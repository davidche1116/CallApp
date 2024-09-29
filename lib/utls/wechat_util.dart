import 'package:call/data/phone_info.dart';
import 'package:wechat_video_call/wechat_video_call.dart';

class WechatUtil {
  factory WechatUtil() => _instance;

  WechatUtil._internal();

  static final WechatUtil _instance = WechatUtil._internal();

  Future<bool> check() async {
    bool status = await WeChatVideoCall.isAccessibilityPermissionEnabled();
    if (!status) {
      status = await WeChatVideoCall.requestAccessibilityPermission();
    }
    return status;
  }

  /// 拨打[info.wechat】微信视频通话
  Future<void> video(PhoneInfo info) async {
    WeChatVideoCall.videoCall(info.wechat);
  }

  Future<bool> requestAccessibilityPermission() async {
    return WeChatVideoCall.requestAccessibilityPermission();
  }

  Future<bool> isAccessibilityPermissionEnabled() async {
    return WeChatVideoCall.isAccessibilityPermissionEnabled();
  }
}
