import 'package:auto_size_text/auto_size_text.dart';
import 'package:call/data/phone_info.dart';
import 'package:call/page/add_page.dart';
import 'package:call/utls/style_util.dart';
import 'package:call/utls/widget_util.dart';
import 'package:flutter/material.dart';

class EditPage extends StatelessWidget {
  const EditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑联系人'),
      ),
      body: ValueListenableBuilder(
          valueListenable: PhoneInfo.globalInfoList,
          builder:
              (BuildContext context, List<PhoneInfo> value, Widget? child) {
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
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AddPage(info: value[index])),
                          );
                        },
                      );
                    },
                  )
                : Center(
                    child: Text(
                      '没有联系人',
                      style: StyleUtil.textStyle,
                    ),
                  );
          }),
    );
  }
}
