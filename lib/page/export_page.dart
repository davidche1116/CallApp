import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:call/data/phone_info.dart';
import 'package:call/utls/style_util.dart';
import 'package:call/utls/widget_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

import '../utls/flavor_util.dart';

class ExportPage extends StatelessWidget {
  const ExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导出照片'),
        actions: [
          IconButton(
            onPressed: () async {
              WidgetUtil.confirmPopup(
                '是否导出所有联系人照片到相册？',
                onTap: () async {
                  await _exportAll();
                  WidgetUtil.showToast('导出成功');
                },
              );
            },
            icon: const Icon(CupertinoIcons.tray),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: PhoneInfo.globalInfoList,
        builder: (BuildContext context, List<PhoneInfo> value, Widget? child) {
          return value.isNotEmpty
              ? ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: WidgetUtil.photoImageIcon(value[index].photo),
                      title: AutoSizeText(
                        value[index].name,
                        style: StyleUtil.textStyle,
                      ),
                      trailing: AutoSizeText(
                        value[index].phone,
                        style: StyleUtil.textStyle,
                      ),
                      onTap: () async {
                        await WidgetUtil.confirmPopup(
                          '是否导出【${value[index].name}】这个联系人的照片到相册？',
                          onTap: () async {
                            WidgetUtil.showLoading('导出中');
                            try {
                              await _export(value[index]);
                              WidgetUtil.hideLoading();
                              WidgetUtil.showToast(
                                '导出【${value[index].name}】成功',
                              );
                            } catch (e) {
                              WidgetUtil.hideLoading();
                              WidgetUtil.showToast(
                                '导出【${value[index].name}】失败',
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                )
              : Center(child: Text('没有联系人', style: StyleUtil.textStyle));
        },
      ),
    );
  }

  Future<void> _export(PhoneInfo info) async {
    if (info.photo.isNotEmpty) {
      Uint8List data;
      if (info.photo.contains('/')) {
        File file = File(info.photo);
        data = await file.readAsBytes();
      } else {
        ByteData bytes = await rootBundle.load(
          'assets/${FlavorUtil.flavor()}/${info.photo}',
        );
        data = bytes.buffer.asUint8List();
      }
      PhotoManager.editor.saveImage(data, filename: '${info.name}.jpg');
    }
  }

  Future<void> _exportAll() async {
    /// 导出照片
    for (PhoneInfo info in PhoneInfo.globalInfoList.value) {
      await _export(info);
    }
  }
}
