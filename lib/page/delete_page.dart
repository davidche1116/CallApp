import 'package:auto_size_text/auto_size_text.dart';
import 'package:call/data/phone_info.dart';
import 'package:call/utls/style_util.dart';
import 'package:call/utls/widget_util.dart';
import 'package:flutter/material.dart';

import '../utls/db_util.dart';

class DeletePage extends StatelessWidget {
  const DeletePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('删除联系人')),
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
                          '是否删除【${value[index].name}】这个联系人？',
                          onTap: () async {
                            await DbUtil().deleteInfo(value[index]);
                            await DbUtil().queryInfo();
                            WidgetUtil.showToast('删除成功');
                          },
                          buttonColor: Colors.red,
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
}
