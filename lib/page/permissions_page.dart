import 'package:call/utls/style_util.dart';
import 'package:call/utls/wechat_util.dart';
import 'package:call/utls/widget_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  static List<String> titleList = ['无障碍', '打电话', '相册', '设置'];

  static List<String> subtitleList = [
    '使用无障碍服务，拨打微信视频',
    '使用拨打电话权限，直接拨号',
    '使用相册权限，添加联系人时选择头像',
    '软件的所有设置',
  ];

  static List<bool> openList = [false, false, false, true];

  static Future<void> _accessible() async {
    bool ret = await WechatUtil().check();
    openList[0] = ret;
    WidgetUtil.showToast('设置${ret ? '成功' : '失败'}');
  }

  static Future<void> _call() async {
    bool ret = await Permission.phone.request().isGranted;
    openList[1] = ret;
    WidgetUtil.showToast('设置${ret ? '成功' : '失败'}');
  }

  static Future<void> _photo() async {
    bool ret = await Permission.photos.request().isGranted;
    openList[2] = ret;
    WidgetUtil.showToast('设置${ret ? '成功' : '失败'}');
  }

  static Future<void> _settings() async {
    openAppSettings();
  }

  static List<Function> funList = [_accessible, _call, _photo, _settings];

  @override
  void initState() {
    super.initState();

    WechatUtil().isAccessibilityPermissionEnabled().then((res) async {
      openList[0] = res;
      openList[1] = await Permission.phone.isGranted;
      openList[2] = await Permission.photos.isGranted;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('权限管理')),
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
        setState(() {});
      },
      child: Card(
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListTile(
            title: Text(titleList[index], style: StyleUtil.textStyle),
            subtitle: Text(subtitleList[index]),
            trailing: Icon(
              openList[index]
                  ? CupertinoIcons.checkmark_alt_circle_fill
                  : CupertinoIcons.xmark_circle,
              color: openList[index]
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }
}
