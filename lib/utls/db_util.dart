import 'dart:async';
import 'dart:typed_data';

import 'package:call/data/call_record.dart';
import 'package:call/data/phone_info.dart';
import 'package:call/data/voice_vibration_set.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:sqflite/sqflite.dart';

import 'flavor_util.dart';

class DbUtil {
  factory DbUtil() => _instance;

  DbUtil._internal();

  static final DbUtil _instance = DbUtil._internal();

  late Database _database;

  Future<void> init() async {
    String path =
        '${await getDatabasesPath()}/${FlavorUtil.flavor()}_database.db';
    _database = await openDatabase(
      path,
      onCreate: (db, version) async {
        /// 创建拨号记录表
        await db.execute('''
          CREATE TABLE CALL_RECORD(
          ID INTEGER PRIMARY KEY,
          PHONE TEXT(32) NOT NULL,
          TIME TEXT(32))
          ''');

        /// 创建微信视频记录表
        await db.execute('''
          CREATE TABLE WECHAT_RECORD(
          ID INTEGER PRIMARY KEY,
          PHONE TEXT(32) NOT NULL,
          TIME TEXT(32))
          ''');

        /// 创建信息表
        await db.execute('''
          CREATE TABLE CALL_INFO(
          ID INTEGER PRIMARY KEY,
          NUM INTEGER DEFAULT 100,
          PHONE TEXT(32) NOT NULL,
          NAME TEXT(32) NOT NULL,
          VOICE TEXT(32),
          WECHAT TEXT(32),
          PHOTO TEXT(256))
          ''');

        /// 创建语音震动配置表
        await db.execute('''
          CREATE TABLE VOICE_SET(
          ID INTEGER PRIMARY KEY,
          VOICE INTEGER DEFAULT 1,
          VOLUME INTEGER DEFAULT 100,
          RATE INTEGER DEFAULT 40,
          PITCH INTEGER DEFAULT 100,
          VIBRATION INTEGER DEFAULT 1,
          DURATION INTEGER DEFAULT 100,
          AMPLITUDE INTEGER DEFAULT 125)
          ''');
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );

    List<PhoneInfo> infoList = await queryInfo();

    /// APP第一次启动数据库为空时，添加数据
    if (infoList.isEmpty) {
      infoList = PhoneInfo.defaultList();
      Batch batch = _database.batch();
      for (int i = 0; i < infoList.length; ++i) {
        infoList[i].num = i;
        batch.insert(
          'CALL_INFO',
          infoList[i].toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit();
      infoList = await queryInfo();
    }

    PhoneInfo.globalInfoList.value = infoList;
  }

  /// 查询所有电话号码信息
  Future<List<PhoneInfo>> queryInfo() async {
    List<Map<String, Object?>> maps = await _database.query(
      'CALL_INFO',
      orderBy: 'NUM',
    );

    // Convert the List<Map<String, dynamic> into a List<PhoneInfo>.
    List<PhoneInfo> ret = List.generate(maps.length, (i) {
      return PhoneInfo(
        maps[i]['NAME'] as String,
        maps[i]['PHONE'] as String,
        maps[i]['PHOTO'] as String,
        id: maps[i]['ID'] as int,
        num: maps[i]['NUM'] as int,
        voice: maps[i]['VOICE'] as String,
        wechat: maps[i]['WECHAT'] as String,
      );
    });
    PhoneInfo.globalInfoList.value = ret;
    return ret;
  }

  /// 根据ID查询电话号码信息
  Future<PhoneInfo?> queryInfoById(int id) async {
    List<Map<String, Object?>> maps = await _database.query(
      'CALL_INFO',
      where: 'ID = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    } else {
      return PhoneInfo(
        maps.first['NAME'] as String,
        maps.first['PHONE'] as String,
        maps.first['PHOTO'] as String,
        id: maps.first['ID'] as int,
        num: maps.first['NUM'] as int,
        voice: maps.first['VOICE'] as String,
        wechat: maps.first['WECHAT'] as String,
      );
    }
  }

  /// 批量添加/修改手机号码信息
  Future<void> updateInfo(PhoneInfo info) async {
    await _database.update(
      'CALL_INFO',
      info.toMap(),
      where: 'ID = ?',
      whereArgs: [info.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量添加/修改手机号码信息
  Future<void> updateInfoList(List<PhoneInfo> list) async {
    Batch batch = _database.batch();
    for (PhoneInfo info in list) {
      batch.update(
        'CALL_INFO',
        info.toMap(),
        where: 'ID = ?',
        whereArgs: [info.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  /// 添加联系人
  Future<void> addInfo(PhoneInfo info) async {
    await _database.insert(
      'CALL_INFO',
      info.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 删除联系人
  Future<void> deleteInfo(PhoneInfo info) async {
    await _database.delete('CALL_INFO', where: 'ID = ?', whereArgs: [info.id]);
  }

  /// 数据库插入[record】通话记录
  Future<void> addRecord(PhoneInfo info) async {
    var record = CallRecord(info.phone, DateTime.now());

    await _database.insert(
      'CALL_RECORD',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 数据库插入[record】通话记录
  Future<void> addWechatRecord(PhoneInfo info) async {
    var record = CallRecord(info.wechat, DateTime.now());

    await _database.insert(
      'WECHAT_RECORD',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 根据时间范围查询通话记录
  Future<List<CallRecord>> queryRecord(String start, String end) async {
    List<Map<String, Object?>> maps = await _database.rawQuery(
      '''
    SELECT CALL_RECORD.ID, CALL_RECORD.PHONE, CALL_RECORD.TIME, CALL_INFO.NAME, CALL_INFO.PHOTO
    FROM CALL_RECORD LEFT OUTER JOIN CALL_INFO
    ON CALL_RECORD.PHONE = CALL_INFO.PHONE
    where
    CALL_RECORD.TIME >= ? AND CALL_RECORD.TIME <= ?
    ORDER BY CALL_RECORD.TIME DESC
    ''',
      [start, '$end 23:59:59'],
    );

    // Convert the List<Map<String, dynamic> into a List<CallRecord>.
    return List.generate(maps.length, (i) {
      return CallRecord(
        maps[i]['PHONE'] as String,
        DateTime.parse(maps[i]['TIME'] as String),
        id: maps[i]['ID'] as int,
        name: maps[i]['NAME'] != null ? maps[i]['NAME'] as String : '',
        photo: maps[i]['PHOTO'] != null ? maps[i]['PHOTO'] as String : '',
      );
    });
  }

  /// 根据时间范围查询通话记录
  Future<List<CallRecord>> queryWechatRecord(String start, String end) async {
    List<Map<String, Object?>> maps = await _database.rawQuery(
      '''
    SELECT WECHAT_RECORD.ID, WECHAT_RECORD.PHONE, WECHAT_RECORD.TIME, CALL_INFO.NAME, CALL_INFO.PHOTO
    FROM WECHAT_RECORD LEFT OUTER JOIN CALL_INFO
    ON WECHAT_RECORD.PHONE = CALL_INFO.WECHAT
    where
    WECHAT_RECORD.TIME >= ? AND WECHAT_RECORD.TIME <= ?
    ORDER BY WECHAT_RECORD.TIME DESC
    ''',
      [start, '$end 23:59:59'],
    );

    // Convert the List<Map<String, dynamic> into a List<CallRecord>.
    return List.generate(maps.length, (i) {
      return CallRecord(
        maps[i]['PHONE'] as String,
        DateTime.parse(maps[i]['TIME'] as String),
        id: maps[i]['ID'] as int,
        name: maps[i]['NAME'] != null ? maps[i]['NAME'] as String : '',
        photo: maps[i]['PHOTO'] != null ? maps[i]['PHOTO'] as String : '',
      );
    });
  }

  /// 获取[phone]今日已拨打次数
  Future<int> getTodayNum(String phone) async {
    List<Map<String, Object?>> maps = await _database.query(
      'CALL_RECORD',
      where: 'PHONE = ? AND TIME >= ?',
      whereArgs: [
        phone,
        '${DateTime.now().toString().substring(0, 10)} 00:00:00',
      ],
    );
    return maps.length;
  }

  /// 删除一条通话记录
  Future<void> deleteRecord(CallRecord record) async {
    await _database.delete('CALL_RECORD', where: 'ID = ${record.id}');
  }

  /// 删除一条通话记录
  Future<void> deleteWechatRecord(CallRecord record) async {
    await _database.delete('WECHAT_RECORD', where: 'ID = ${record.id}');
  }

  /// 删除所有通话记录
  Future<void> deleteAllRecord() async {
    await _database.delete('CALL_RECORD');
  }

  /// 删除所有通话记录
  Future<void> deleteAllWechatRecord() async {
    await _database.delete('WECHAT_RECORD');
  }

  /// 保存语音播报配置
  Future<void> setVoiceVibration(VoiceVibrationSet set) async {
    await _database.insert(
      'VOICE_SET',
      set.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取语音播报配置
  Future<VoiceVibrationSet> getVoiceVibration() async {
    List<Map<String, Object?>> maps = await _database.query(
      'VOICE_SET',
      where: 'ID = 0',
    );

    // Convert the List<Map<String, dynamic> into a List<VoiceSet>.
    List<VoiceVibrationSet> list = List.generate(maps.length, (i) {
      return VoiceVibrationSet(
        maps[i]['VOICE'] as int == 1,
        maps[i]['VOLUME'] as int,
        maps[i]['RATE'] as int,
        maps[i]['PITCH'] as int,
        maps[i]['VIBRATION'] as int == 1,
        maps[i]['DURATION'] as int,
        maps[i]['AMPLITUDE'] as int,
      );
    });

    if (list.isNotEmpty) {
      return list.first;
    } else {
      return VoiceVibrationSet.defaultVoiceVibrationSet;
    }
  }

  Future<void> cleanAllTab() async {
    await _database.delete('CALL_RECORD');
    await _database.delete('WECHAT_RECORD');
    await _database.delete('CALL_INFO');
    await DbUtil().queryInfo();
  }

  Future<Uint8List> getDataBytes() async {
    String path =
        '${await getDatabasesPath()}/${FlavorUtil.flavor()}_database.db';
    await _database.close();
    XFile file = XFile(path);
    Uint8List bytes = await file.readAsBytes();
    _database = await openDatabase(path);
    return bytes;
  }

  Future<void> import(String path) async {
    String pathOld =
        '${await getDatabasesPath()}/${FlavorUtil.flavor()}_database.db';
    await _database.close();
    await deleteDatabase(pathOld);
    XFile file = XFile(path);
    await file.saveTo(pathOld);
    _database = await openDatabase(pathOld);
    await DbUtil().queryInfo();
  }
}
