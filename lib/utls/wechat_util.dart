import 'dart:async';

import 'package:call/data/phone_info.dart';
import 'package:wechat_video_call/wechat_video_call.dart';

/// 微信视频拨打封装（wechat_video_call 2.0）。
///
/// 2.0 要点：
/// - 拨号前必须完成坐标校准（否则 `videoCall` 返回 false / WVC_0004）
/// - `requestXxxPermission` 返回的是「当前」授权状态，设置页返回后需重查
/// - `videoCall` 的 true 仅表示会话启动，结果看 [events]
/// - 悬浮窗仅校准向导需要，拨号不依赖
class WechatUtil {
  factory WechatUtil() => _instance;

  WechatUtil._internal();

  static final WechatUtil _instance = WechatUtil._internal();

  StreamSubscription<WeChatCallEvent>? _sub;

  /// 插件事件流（拨打进度 / 校准 / 失败码）。
  Stream<WeChatCallEvent> get events => WeChatVideoCall.events;

  /// 统一权限与环境状态。
  Future<WvcPermissionStatus> permissionStatus() {
    return WeChatVideoCall.getPermissionStatus();
  }

  /// 校准进度（是否可拨、缺哪些点）。
  Future<WvcCalibrationProgress> calibrationProgress() {
    return WeChatVideoCall.getCalibrationProgress();
  }

  /// 检查无障碍；未开启则跳系统设置。
  ///
  /// 返回值是调用瞬间的状态：跳设置时通常为 false，需在 resumed 后重查。
  Future<bool> checkAccessibility() async {
    final enabled = await WeChatVideoCall.isAccessibilityPermissionEnabled();
    if (enabled) return true;
    return WeChatVideoCall.requestAccessibilityPermission();
  }

  /// 检查悬浮窗；未授予则跳系统设置（校准向导需要）。
  Future<bool> checkOverlay() async {
    final enabled = await WeChatVideoCall.isOverlayPermissionEnabled();
    if (enabled) return true;
    return WeChatVideoCall.requestOverlayPermission();
  }

  /// 兼容旧调用：无障碍检查 + 必要时跳设置。
  ///
  /// 注意：2.0 下返回 false 不一定是最终拒绝，可能是「已打开设置页」。
  Future<bool> check() => checkAccessibility();

  Future<bool> isAccessibilityPermissionEnabled() {
    return WeChatVideoCall.isAccessibilityPermissionEnabled();
  }

  Future<bool> requestAccessibilityPermission() {
    return WeChatVideoCall.requestAccessibilityPermission();
  }

  Future<bool> isOverlayPermissionEnabled() {
    return WeChatVideoCall.isOverlayPermissionEnabled();
  }

  Future<bool> requestOverlayPermission() {
    return WeChatVideoCall.requestOverlayPermission();
  }

  Future<bool> isWeChatInstalled() => WeChatVideoCall.isWeChatInstalled();

  /// 视频通话是否已录齐必录点。
  Future<bool> isReadyForVideo() async {
    final p = await WeChatVideoCall.getCalibrationProgress();
    return p.readyForVideo;
  }

  /// 打开插件内置悬浮校准向导（需先授予悬浮窗）。
  Future<bool> openCalibrationWizard() async {
    final overlay = await checkOverlay();
    if (!overlay) return false;
    return WeChatVideoCall.openCalibrationWizard();
  }

  Future<bool> stopCalibration() => WeChatVideoCall.stopCalibration();

  /// 校准就绪检查；未就绪时 [onNeedCalibration] 收到缺失步骤文案。
  Future<bool> ensureCalibrated({
    void Function(String message)? onNeedCalibration,
  }) async {
    final p = await WeChatVideoCall.getCalibrationProgress();
    if (p.readyForVideo) return true;
    final missing = p.missingRequiredStepIds;
    final text = missing.isEmpty
        ? '请先完成微信视频坐标校准'
        : '请先完成校准，还缺：${missing.join('、')}';
    onNeedCalibration?.call(text);
    return false;
  }

  /// 拨打 [info.wechat] 微信视频通话。
  ///
  /// 仅 Android。返回 true 表示会话已启动（不代表对方接听）。
  Future<bool> video(
    PhoneInfo info, {
    void Function(String message)? onStatus,
  }) async {
    final name = info.wechat.trim();
    if (name.isEmpty) {
      onStatus?.call('联系人未填写微信备注');
      return false;
    }
    final status = await WeChatVideoCall.getPermissionStatus();
    if (!status.accessibility) {
      onStatus?.call('没有无障碍权限，请先开启');
      await checkAccessibility();
      return false;
    }
    if (!status.wechatInstalled) {
      onStatus?.call(WeChatVideoCall.errorMessage(WvcErrorCodes.wechatNotInstalled));
      return false;
    }
    if (status.calibrationActive) {
      onStatus
          ?.call(WeChatVideoCall.errorMessage(WvcErrorCodes.calibrationInProgress));
      return false;
    }
    final ok = await ensureCalibrated(onNeedCalibration: onStatus);
    if (!ok) return false;

    onStatus?.call('正在控制手机');
    return WeChatVideoCall.videoCall(name);
  }

  /// 拨打语音通话（与 [video] 相同的就绪检查）。
  Future<bool> voice(
    PhoneInfo info, {
    void Function(String message)? onStatus,
  }) async {
    final name = info.wechat.trim();
    if (name.isEmpty) {
      onStatus?.call('联系人未填写微信备注');
      return false;
    }
    final status = await WeChatVideoCall.getPermissionStatus();
    if (!status.accessibility) {
      onStatus?.call('没有无障碍权限，请先开启');
      await checkAccessibility();
      return false;
    }
    if (!status.wechatInstalled) {
      onStatus
          ?.call(WeChatVideoCall.errorMessage(WvcErrorCodes.wechatNotInstalled));
      return false;
    }
    if (status.calibrationActive) {
      onStatus
          ?.call(WeChatVideoCall.errorMessage(WvcErrorCodes.calibrationInProgress));
      return false;
    }
    final progress = await WeChatVideoCall.getCalibrationProgress();
    if (!progress.readyForVoice) {
      final missing = progress.missingRequiredStepIds;
      onStatus?.call(
        missing.isEmpty
            ? '请先完成微信语音通话坐标校准'
            : '请先完成校准，还缺：${missing.join('、')}',
      );
      return false;
    }

    onStatus?.call('正在控制手机');
    return WeChatVideoCall.voiceCall(name);
  }

  /// 取消进行中的拨打会话。
  Future<bool> cancel() => WeChatVideoCall.cancel();

  /// 点击已录的挂断坐标。
  Future<bool> hangUp() => WeChatVideoCall.hangUp();

  /// 订阅事件；重复调用会替换回调。传 null 取消订阅。
  void subscribeEvents(void Function(WeChatCallEvent event)? onEvent) {
    _sub?.cancel();
    _sub = null;
    if (onEvent == null) return;
    _sub = WeChatVideoCall.events.listen(onEvent);
  }

  /// 将失败事件转成用户可读文案。
  static String describeEvent(WeChatCallEvent e) {
    if (e.type == WvcEventTypes.sessionFailed) {
      final code = e.errorCode;
      if (code != null) return WeChatVideoCall.errorMessage(code);
      return e.message ?? '拨打失败';
    }
    if (e.type == WvcEventTypes.sessionSuccess) {
      return '拨打流程已完成，请在微信中查看';
    }
    if (e.type == WvcEventTypes.sessionStarted) {
      return '已开始拨打流程';
    }
    if (e.type == WvcEventTypes.configMismatch) {
      return WeChatVideoCall.errorMessage(WvcErrorCodes.configMismatch);
    }
    return e.message ?? e.type;
  }
}
