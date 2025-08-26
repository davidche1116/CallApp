import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:call/data/phone_info.dart';
import 'package:call/utls/db_util.dart';
import 'package:call/utls/style_util.dart';
import 'package:call/utls/widget_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReorderPage extends StatefulWidget {
  const ReorderPage({super.key});

  @override
  State<ReorderPage> createState() => _ReorderPageState();
}

class _ReorderPageState extends State<ReorderPage> {
  List<PhoneInfo> _phoneInfoList = PhoneInfo.defaultList();

  @override
  void initState() {
    super.initState();
    _phoneInfoList = PhoneInfo.globalInfoList.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('联系人排序'),
        actions: [
          IconButton(
            onPressed: () async {
              await WidgetUtil.confirmPopup(
                '是否保存全新顺序？',
                onTap: () async {
                  try {
                    for (int i = 0; i < _phoneInfoList.length; ++i) {
                      _phoneInfoList[i].num = i;
                    }
                    await DbUtil().updateInfoList(_phoneInfoList);
                    await DbUtil().queryInfo();
                    WidgetUtil.showToast('保存成功！');
                  } catch (e) {
                    WidgetUtil.showToast('保存失败，请重试');
                  }
                },
              );
            },
            icon: const Icon(CupertinoIcons.tray),
            tooltip: '保存排序',
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _phoneInfoList.length,
        itemBuilder: (context, index) {
          final item = _phoneInfoList[index];
          return Card(
            key: Key('$index'),
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: item.color(show: true),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: WidgetUtil.photoImageIcon(item.photo),
              title: AutoSizeText(
                item.name,
                style: StyleUtil.textStyle.copyWith(color: Colors.white),
                maxLines: 1,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AutoSizeText(
                    item.phone,
                    style: StyleUtil.textStyle.copyWith(color: Colors.white),
                    maxLines: 1,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.drag_handle),
                ],
              ),
            ),
          );
        },
        onReorderStart: (index) {
          HapticFeedback.mediumImpact();
        },
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final PhoneInfo item = _phoneInfoList.removeAt(oldIndex);
            _phoneInfoList.insert(newIndex, item);
          });
          HapticFeedback.lightImpact();
        },
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final double scale = lerpDouble(1, 1.08, animation.value)!;
              return Transform.scale(scale: scale, child: child);
            },
            child: child,
          );
        },
      ),
    );
  }
}
