import 'package:flutter_test/flutter_test.dart';
import 'package:wechat_video_call/wechat_video_call.dart';

import 'package:call/utls/wechat_util.dart';

void main() {
  test('describeEvent maps session failure codes to Chinese copy', () {
    const failed = WeChatCallEvent(WvcEventTypes.sessionFailed, {
      'errorCode': WvcErrorCodes.configMissing,
    });
    expect(WechatUtil.describeEvent(failed), contains('校准'));

    const started = WeChatCallEvent(WvcEventTypes.sessionStarted, {});
    expect(WechatUtil.describeEvent(started), contains('已开始'));

    const success = WeChatCallEvent(WvcEventTypes.sessionSuccess, {});
    expect(WechatUtil.describeEvent(success), contains('完成'));
  });
}
