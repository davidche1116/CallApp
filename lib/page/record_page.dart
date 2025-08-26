import 'package:auto_size_text/auto_size_text.dart';
import 'package:call/data/call_record.dart';
import 'package:call/utls/db_util.dart';
import 'package:call/utls/style_util.dart';
import 'package:call/utls/widget_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPage();
}

class _RecordPage extends State<RecordPage> {
  final ValueNotifier<List<CallRecord>> _callRecordList =
      ValueNotifier<List<CallRecord>>([]);

  final ValueNotifier<bool> _isWechat = ValueNotifier(false);

  String _startDate = DateTime.now()
      .subtract(const Duration(days: 7))
      .toString()
      .substring(0, 10);
  String _endDate = DateTime.now().toString().substring(0, 10);

  @override
  void initState() {
    super.initState();

    DbUtil().queryRecord(_startDate, _endDate).then((list) {
      _callRecordList.value = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text(_isWechat ? '视频记录' : '拨号记录'),
        title: ValueListenableBuilder(
          valueListenable: _isWechat,
          builder: (BuildContext context, bool value, Widget? child) {
            return Text(value ? '微信记录' : '拨号记录');
          },
        ),
        actions: [
          IconButton(
            onPressed: () async {
              _isWechat.value = !_isWechat.value;
              if (_isWechat.value) {
                DbUtil().queryWechatRecord(_startDate, _endDate).then((list) {
                  _callRecordList.value = list;
                });
              } else {
                DbUtil().queryRecord(_startDate, _endDate).then((list) {
                  _callRecordList.value = list;
                });
              }
            },
            icon: const Icon(CupertinoIcons.arrow_right_arrow_left_circle),
          ),
          IconButton(
            onPressed: () async {
              await WidgetUtil.confirmPopup(
                '是否删除全部${_isWechat.value ? '视频' : '通话'}记录？',
                buttonColor: Colors.red,
                onTap: () async {
                  if (_isWechat.value) {
                    await DbUtil().deleteAllWechatRecord();
                  } else {
                    await DbUtil().deleteAllRecord();
                  }

                  _callRecordList.value = [];
                  WidgetUtil.showToast('删除成功');
                },
              );
            },
            icon: const Icon(CupertinoIcons.delete),
          ),
          IconButton(
            onPressed: () async {
              DateTimeRange? selectTimeRange = await showDateRangePicker(
                //语言环境
                // locale: Locale("zh", "CH"),
                context: context,
                //开始时间
                firstDate: DateTime(2024, 1, 1),
                //结束时间
                lastDate: DateTime(2050, 1, 1),
                cancelText: "取消",
                confirmText: "确定",
                //初始的时间范围选择
                initialDateRange: DateTimeRange(
                  start: DateTime.parse(_startDate),
                  end: DateTime.parse(_endDate),
                ),
              );

              if (selectTimeRange != null) {
                _startDate = selectTimeRange.start.toString().substring(0, 10);
                _endDate = selectTimeRange.end.toString().substring(0, 10);
                List<CallRecord> list = await DbUtil().queryRecord(
                  _startDate,
                  _endDate,
                );
                _callRecordList.value = list;
                WidgetUtil.showToast('刷新完成');
              }
            },
            icon: const Icon(CupertinoIcons.time),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _callRecordList,
        builder: (BuildContext context, List<CallRecord> value, Widget? child) {
          return value.isNotEmpty
              ? ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: WidgetUtil.photoImageIcon(value[index].photo),
                      title: AutoSizeText(value[index].name),
                      subtitle: AutoSizeText(value[index].phone),
                      trailing: AutoSizeText(
                        value[index].time.toString().substring(0, 19),
                      ),
                      onTap: () async {
                        await WidgetUtil.confirmPopup(
                          '是否删除【${value[index].name}】这条记录？',
                          onTap: () async {
                            if (_isWechat.value) {
                              await DbUtil().deleteWechatRecord(value[index]);
                              _callRecordList.value = await DbUtil()
                                  .queryWechatRecord(_startDate, _endDate);
                            } else {
                              await DbUtil().deleteRecord(value[index]);
                              _callRecordList.value = await DbUtil()
                                  .queryRecord(_startDate, _endDate);
                            }

                            WidgetUtil.showToast('删除成功');
                          },
                          buttonColor: Colors.red,
                        );
                      },
                    );
                  },
                )
              : Center(child: Text('没有记录', style: StyleUtil.textStyle));
        },
      ),
    );
  }
}
