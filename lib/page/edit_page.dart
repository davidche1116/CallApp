import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:call/data/phone_info.dart';
import 'package:call/page/add_page.dart';
import 'package:call/utls/db_util.dart';
import 'package:call/utls/flavor_util.dart';
import 'package:call/utls/style_util.dart';
import 'package:call/utls/widget_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:photo_manager/photo_manager.dart';

class EditPage extends StatelessWidget {
  const EditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑联系人'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPage()),
              );
            },
            icon: const Icon(CupertinoIcons.add_circled),
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
                    return Slidable(
                      key: Key(value[index].phone),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) async {
                              await DbUtil().deleteInfo(value[index]);
                              await DbUtil().queryInfo();
                              WidgetUtil.showToast('删除成功');
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: CupertinoIcons.delete,
                            label: '删除',
                          ),
                          SlidableAction(
                            onPressed: (context) async {
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
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            icon: CupertinoIcons.photo_on_rectangle,
                            label: '导出',
                          ),
                        ],
                      ),
                      child: ListTile(
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
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddPage(info: value[index]),
                            ),
                          );
                        },
                      ),
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
}
