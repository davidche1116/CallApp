import 'dart:typed_data';

import 'package:call/utls/db_util.dart';
import 'package:call/utls/style_util.dart';
import 'package:call/utls/widget_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class DataPage extends StatelessWidget {
  const DataPage({super.key});

  static List<String> titleList = ['清空数据库', '导入数据库', '导出数据库'];

  static List<String> subtitleList = [
    '清空所有数据，清空所有联系人信息',
    '从手机文件中选择一个数据库，替换当前数据库（表格式必须相同，否则软件会故障）',
    '将当前数据库导出并（不包含图片信息）',
  ];

  static Future<void> _clear() async {
    WidgetUtil.confirmPopup(
      '是否清空所有数据？不可恢复！',
      onTap: () async {
        await DbUtil().cleanAllTab();
        WidgetUtil.showToast('已清空');
      },
    );
  }

  static Future<void> _import() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      await DbUtil().import(result.paths.first!);
    }
    WidgetUtil.showToast(result != null ? '导入成功' : '取消导入');
  }

  static Future<void> _export() async {
    Uint8List bytes = await DbUtil().getDataBytes();
    String? outputFile = await FilePicker.platform.saveFile(
      fileName: 'call_info.db',
      bytes: bytes,
    );
    WidgetUtil.showToast(outputFile != null ? '导出成功' : '取消导出');
  }

  static List<Function> funList = [_clear, _import, _export];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据库管理')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [for (int i = 0; i < titleList.length; ++i) _buildItem(i)],
      ),
    );
  }

  Widget _buildItem(int index) {
    return GestureDetector(
      onTap: () async {
        await funList[index]();
      },
      child: Card(
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListTile(
            title: Text(titleList[index], style: StyleUtil.textStyle),
            subtitle: Text(subtitleList[index]),
          ),
        ),
      ),
    );
  }
}
