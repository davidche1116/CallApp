import 'package:flutter/material.dart';

/// 卡片手机号码信息
class PhoneInfo {
  PhoneInfo(
    this.name,
    this.phone,
    this.photo, {
    this.id = -1,
    this.num = 0,
    this.voice = '',
    this.wechat = '',
  });

  final int id;

  /// 姓名，当[photo]为空时显示姓名
  String name;

  /// 拨打的号码
  String phone;

  /// 头像图片在assets/$flavor目录下的名称，可以为空
  /// 添加的头像图片在APP缓存目录包名目录中绝对路径
  String photo;

  /// 显示序号
  int num;

  /// 语音播报
  String voice;

  /// 微信视频
  String wechat;

  /// 没有头像只显示姓名时，卡片的背景色
  /// [show]为true时，强制显示颜色
  Color color({bool show = false}) {
    return (photo.isEmpty || show)
        ? Colors.primaries[int.parse(phone) % Colors.primaries.length].shade400
        : Colors.transparent;
  }

  // Convert into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    if (id < 0) {
      return {
        'NAME': name,
        'PHONE': phone,
        'PHOTO': photo,
        'NUM': num,
        'VOICE': voice,
        'WECHAT': wechat,
      };
    } else {
      return {
        'ID': id,
        'NAME': name,
        'PHONE': phone,
        'PHOTO': photo,
        'NUM': num,
        'VOICE': voice,
        'WECHAT': wechat,
      };
    }
  }

  @override
  String toString() {
    return 'CALL_INFO{ID: $id, PHONE: $phone, NUM: $num, NAME: $name, PHOTO: $photo, VOICE: $voice, WECHAT: $wechat}';
  }

  static List<PhoneInfo> defaultList() {
    return _listGithub;
  }

  /// 全局电话信息（每个界面都用）
  static ValueNotifier<List<PhoneInfo>> globalInfoList = ValueNotifier(
    defaultList(),
  );

  /// github
  static final List<PhoneInfo> _listGithub = [];
}
