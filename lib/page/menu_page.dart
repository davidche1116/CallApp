import 'package:animations/animations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:call/page/about_page.dart';
import 'package:call/page/add_page.dart';
import 'package:call/page/data_page.dart';
import 'package:call/page/delete_page.dart';
import 'package:call/page/edit_page.dart';
import 'package:call/page/export_page.dart';
import 'package:call/page/permissions_page.dart';
import 'package:call/page/record_page.dart';
import 'package:call/page/reorder_page.dart';
import 'package:call/page/voice_vibration_page.dart';
import 'package:call/utls/style_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MenuPage extends StatelessWidget {
  MenuPage({super.key});

  final List<String> _menuList = [
    '通话记录',
    '语音震动',
    '添加联系人',
    '编辑联系人',
    '删除联系人',
    '联系人排序',
    '权限管理',
    '导出照片',
    '数据库管理',
    '关于信息',
  ];

  final List<IconData> _iconList = [
    CupertinoIcons.square_list,
    CupertinoIcons.bell,
    CupertinoIcons.person_badge_plus,
    CupertinoIcons.captions_bubble,
    CupertinoIcons.trash,
    CupertinoIcons.square_stack,
    CupertinoIcons.exclamationmark_shield,
    CupertinoIcons.photo_on_rectangle,
    CupertinoIcons.tray_full,
    CupertinoIcons.house,
  ];

  final List<Widget> _pageList = [
    const RecordPage(),
    const VoiceVibrationPage(),
    const AddPage(),
    const EditPage(),
    const DeletePage(),
    const ReorderPage(),
    const PermissionsPage(),
    const ExportPage(),
    const DataPage(),
    const AboutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    List<Widget> listMenu =
        [
              for (final menu in _menuList)
                _menuCard(_menuList.indexOf(menu), context),
            ]
            .animate(interval: const Duration(milliseconds: 100))
            .flip(duration: const Duration(milliseconds: 500))
            .fade(duration: const Duration(milliseconds: 300));

    return Scaffold(
      appBar: AppBar(title: const Text('菜单')),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return GridView.count(
            crossAxisCount: orientation == Orientation.portrait ? 2 : 4,
            padding: const EdgeInsets.all(5),
            childAspectRatio: 1.2,
            children: [...listMenu],
          );
        },
      ),
    );
  }

  Widget _menuCard(int index, BuildContext context) {
    final color = Colors.primaries[index % Colors.primaries.length];
    return OpenContainer(
      closedColor: Colors.transparent,
      middleColor: Color.lerp(
        color.shade500,
        Theme.of(context).scaffoldBackgroundColor,
        0.5,
      ),
      openColor: Theme.of(context).scaffoldBackgroundColor,
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 500),
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      closedElevation: 4,
      closedBuilder: (context, action) {
        return Card(
          color: color.shade500,
          elevation: 0,
          child: InkWell(
            onTap: action,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _iconList[index],
                    size: MediaQuery.of(context).size.shortestSide / 8,
                  ),
                  const SizedBox(height: 12),
                  AutoSizeText(
                    _menuList[index],
                    style: StyleUtil.textLargeWhite.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      openShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      openBuilder: (context, action) {
        return _pageList[index];
      },
    );
  }
}
