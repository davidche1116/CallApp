import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:call/data/phone_info.dart';
import 'package:call/utls/db_util.dart';
import 'package:call/utls/style_util.dart';
import 'package:call/utls/widget_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    final List<Card> cards = <Card>[
      for (int index = 0; index < _phoneInfoList.length; index += 1)
        Card(
          key: Key('$index'),
          color: _phoneInfoList[index].color(show: true),
          child: SizedBox(
              height: 60,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: AutoSizeText(
                    '${_phoneInfoList[index].name} ${_phoneInfoList[index].phone}',
                    style: StyleUtil.textLargeBlack,
                  ),
                ),
              )),
        ),
    ];

    Widget proxyDecorator(
        Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.02, animValue)!;
          return Transform.scale(
            scale: scale,
            // Create a Card based on the color and the content of the dragged one
            // and set its elevation to the animated value.
            child: Card(
              elevation: elevation,
              color: cards[index].color,
              child: cards[index].child,
            ),
          );
        },
        child: child,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('联系人排序'),
        actions: [
          IconButton(
            onPressed: () async {
              await WidgetUtil.confirmPopup('是否保存全新顺序？', onTap: () async {
                for (int i = 0; i < _phoneInfoList.length; ++i) {
                  _phoneInfoList[i].num = i;
                }
                await DbUtil().updateInfoList(_phoneInfoList);
                await DbUtil().queryInfo();
                WidgetUtil.showToast('保存成功！');
              });
            },
            icon: const Icon(
              CupertinoIcons.tray,
            ),
          ),
        ],
      ),
      body: ReorderableListView(
        padding: const EdgeInsets.all(10),
        proxyDecorator: proxyDecorator,
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final PhoneInfo item = _phoneInfoList.removeAt(oldIndex);
            _phoneInfoList.insert(newIndex, item);
          });
        },
        children: cards,
      ),
    );
  }
}
