import 'dart:async';

import 'package:call/utls/style_util.dart';
import 'package:call/utls/wechat_util.dart';
import 'package:call/utls/widget_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_video_call/wechat_video_call.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage>
    with WidgetsBindingObserver {
  static List<String> titleList = [
    '无障碍',
    '微信坐标校准',
    '悬浮窗',
    '打电话',
    '相册',
    '设置',
  ];

  static List<String> subtitleList = [
    '使用无障碍服务，拨打微信视频',
    '录点向导，首次使用或微信界面变化后必须完成',
    '校准向导悬浮窗权限（仅校准时需要）',
    '使用拨打电话权限，直接拨号',
    '使用相册权限，添加联系人时选择头像',
    '软件的所有设置',
  ];

  List<bool> openList = [false, false, false, false, false, true];
  String calibrationHint = '';
  StreamSubscription<WeChatCallEvent>? _eventSub;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _eventSub = WechatUtil().events.listen((e) {
      if (e.type == WvcEventTypes.calibrationProgress ||
          e.type == WvcEventTypes.sessionFailed ||
          e.type == WvcEventTypes.configMismatch) {
        _refresh();
      }
    });
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 2.0 权限 API 只返回「当前」状态，从系统设置返回后必须重查。
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    try {
      final status = await WechatUtil().permissionStatus();
      final progress = await WechatUtil().calibrationProgress();
      final phone = await Permission.phone.isGranted;
      final photos = await Permission.photos.isGranted;
      if (!mounted) return;
      setState(() {
        openList[0] = status.accessibility;
        openList[1] = progress.readyForVideo;
        openList[2] = status.overlay;
        openList[3] = phone;
        openList[4] = photos;
        openList[5] = true;
        calibrationHint = progress.readyForVideo
            ? '视频通话校准已完成'
            : (progress.missingRequiredStepIds.isEmpty
                  ? '尚未校准，请完成录点'
                  : '还缺：${progress.missingRequiredStepIds.join('、')}');
      });
    } catch (_) {
      // 插件未注册等场景下保持默认关闭态
    }
  }

  Future<void> _accessible() async {
    // 返回值是当前状态；跳设置后通常为 false，以 resumed 重查为准。
    await WechatUtil().checkAccessibility();
    WidgetUtil.showToast('请在系统设置中开启无障碍服务，返回后自动刷新');
    await _refresh();
  }

  Future<void> _calibration() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final overlay = await WechatUtil().checkOverlay();
      if (!overlay) {
        WidgetUtil.showToast('请先授予悬浮窗权限后重试');
        await _refresh();
        return;
      }
      final ok = await WeChatVideoCall.openCalibrationWizard();
      if (!ok) {
        WidgetUtil.showToast(
          WeChatVideoCall.errorMessage(WvcErrorCodes.overlayDisabled),
        );
      } else {
        WidgetUtil.showToast('请按悬浮向导提示，在微信中完成录点');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _refresh();
      }
    }
  }

  Future<void> _exportConfig() async {
    final json = await WeChatVideoCall.exportConfig();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出校准配置'),
        content: SelectableText(json ?? '尚无配置，请先完成校准'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _importConfig() async {
    final controller = TextEditingController();
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入校准配置'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '粘贴 exportConfig 导出的 JSON',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await WeChatVideoCall.importConfig(controller.text.trim());
    WidgetUtil.showToast(success ? '导入成功' : '导入失败，请检查 JSON');
    await _refresh();
  }

  Future<void> _resetConfig() async {
    final ok = await WeChatVideoCall.resetConfig();
    WidgetUtil.showToast(ok ? '已重置全部录点' : '重置失败');
    await _refresh();
  }

  Future<void> _overlay() async {
    await WechatUtil().checkOverlay();
    WidgetUtil.showToast('请在系统设置中授予悬浮窗权限，返回后自动刷新');
    await _refresh();
  }

  Future<void> _call() async {
    bool ret = await Permission.phone.request().isGranted;
    openList[3] = ret;
    WidgetUtil.showToast('设置${ret ? '成功' : '失败'}');
  }

  Future<void> _photo() async {
    bool ret = await Permission.photos.request().isGranted;
    openList[4] = ret;
    WidgetUtil.showToast('设置${ret ? '成功' : '失败'}');
  }

  Future<void> _settings() async {
    openAppSettings();
  }

  late final List<Function> funList = [
    _accessible,
    _calibration,
    _overlay,
    _call,
    _photo,
    _settings,
  ];

  Future<void> _showConfigActions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('导出校准配置'),
              onTap: () {
                Navigator.pop(context);
                _exportConfig();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('导入校准配置'),
              onTap: () {
                Navigator.pop(context);
                _importConfig();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('重置全部录点'),
              onTap: () {
                Navigator.pop(context);
                _resetConfig();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('权限管理')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          if (calibrationHint.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                calibrationHint,
                style: StyleUtil.trailingTextStyle.copyWith(
                  color: openList[1]
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          for (int i = 0; i < titleList.length; ++i) _buildItem(i),
        ],
      ),
    );
  }

  Widget _buildItem(int index) {
    final String subtitle = index == 1 && calibrationHint.isNotEmpty
        ? '$calibrationHint\n${subtitleList[index]}\n长按可导入/导出/重置配置'
        : subtitleList[index];
    return GestureDetector(
      onTap: () async {
        await funList[index]();
        setState(() {});
      },
      onLongPress: index == 1
          ? () {
              _showConfigActions();
            }
          : null,
      child: Card(
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListTile(
            title: Text(titleList[index], style: StyleUtil.textStyle),
            subtitle: Text(subtitle, style: StyleUtil.trailingTextStyle),
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
