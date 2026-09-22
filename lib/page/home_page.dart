import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:android_intent_plus/android_intent.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:call/data/phone_info.dart';
import 'package:call/utls/db_util.dart';
import 'package:call/utls/flavor_util.dart';
import 'package:call/utls/style_util.dart';
import 'package:call/utls/voice_vibration_util.dart';
import 'package:call/utls/wechat_util.dart';
import 'package:call/utls/widget_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wechat_video_call/wechat_video_call.dart';

import 'menu_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  /// 拨打前缓存的微信就绪状态（无障碍 + 校准）。
  bool _wechatReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WechatUtil().subscribeEvents(_onWvcEvent);
    _refreshWechatReady();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WechatUtil().subscribeEvents(null);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshWechatReady();
    }
  }

  Future<void> _refreshWechatReady() async {
    if (!Platform.isAndroid) {
      if (mounted) setState(() => _wechatReady = false);
      return;
    }
    try {
      final status = await WechatUtil().permissionStatus();
      final progress = await WechatUtil().calibrationProgress();
      if (!mounted) return;
      setState(() {
        // 2.0：无障碍 + 已装微信 + 必录点齐全才可点视频。
        _wechatReady = status.accessibility &&
            status.wechatInstalled &&
            progress.readyForVideo;
      });
    } catch (_) {
      if (mounted) setState(() => _wechatReady = false);
    }
  }

  void _onWvcEvent(WeChatCallEvent e) {
    final msg = WechatUtil.describeEvent(e);
    // 只提示关键结果，避免 stepProgress 刷屏。
    if (e.type == WvcEventTypes.sessionFailed ||
        e.type == WvcEventTypes.sessionSuccess ||
        e.type == WvcEventTypes.sessionStarted ||
        e.type == WvcEventTypes.configMismatch) {
      WidgetUtil.showToast(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Theme.of(context).brightness,
    );
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return ValueListenableBuilder(
              valueListenable: PhoneInfo.globalInfoList,
              builder:
                  (BuildContext context, List<PhoneInfo> value, Widget? child) {
                    return value.isNotEmpty
                        ? GridView.count(
                            crossAxisCount: orientation == Orientation.portrait
                                ? 2
                                : 4,
                            padding: const EdgeInsets.all(5),
                            childAspectRatio: 1.2,
                            children: List.generate(value.length, (i) {
                              return _infoCard(context, value[i]);
                            }),
                          )
                        : _noContact(context, orientation);
                  },
            );
          },
        ),
      ),
    );
  }

  Widget _noContact(BuildContext context, Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 20,
            children: [
              Icon(
                CupertinoIcons.person_2,
                size: 200,
                color: Theme.of(context).colorScheme.primary,
              ),
              Text(
                '没有联系人',
                style: StyleUtil.buttonTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              ListTile(
                subtitle: Text(
                  '注意：当有联系人之后，想要进入菜单的话，需要长按任意一个联系人不松手，1秒后手指拖动至屏幕最左上角后再松开！切记切记！！！',
                  style: StyleUtil.trailingTextStyle,
                ),
              ),
              SizedBox(height: 60),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MenuPage()),
                  );
                },
                child: SizedBox(
                  width: 160,
                  height: 60,
                  child: Center(
                    child: Text('进入菜单', style: StyleUtil.textStyle),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 20,
                children: [
                  Icon(
                    CupertinoIcons.person_2,
                    size: 180,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Text(
                    '没有联系人',
                    style: StyleUtil.buttonTextStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 60,
                children: [
                  SizedBox(
                    width: 300,
                    child: Text(
                      '注意：当有联系人之后，想要进入菜单的话，需要长按任意一个联系人不松手，1秒后手指拖动至屏幕最左上角后再松开！切记切记！！！',
                      style: StyleUtil.trailingTextStyle,
                      maxLines: 10,
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MenuPage()),
                      );
                    },
                    child: SizedBox(
                      width: 160,
                      height: 60,
                      child: Center(
                        child: Text('进入菜单', style: StyleUtil.textStyle),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _infoCard(BuildContext context, PhoneInfo info) {
    Offset startOffset = Offset.infinite;
    return GestureDetector(
      onTap: () => _showDialog(info),
      onLongPressStart: (LongPressStartDetails details) {
        startOffset = details.globalPosition;
      },
      onLongPressEnd: (LongPressEndDetails details) {
        Offset endOffset = details.globalPosition;
        bool distance = (endOffset - startOffset).distance > 100;
        bool leftTop = (endOffset.dx < 100 && endOffset.dy < 100);
        if (distance && leftTop) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MenuPage()),
          );
        } else if (!distance) {
          _showDialog(info);
        }
      },
      child: Card(color: info.color(), child: _picture(info)),
    );
  }

  Widget _picture(PhoneInfo info) {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: info.photo.isNotEmpty
            ? info.photo.contains('/')
                  ? Image.file(
                      File(info.photo),
                      fit: BoxFit.cover,
                      errorBuilder: WidgetUtil.errorImage,
                    )
                  : Image.asset(
                      'assets/${FlavorUtil.flavor()}/${info.photo}',
                      fit: BoxFit.cover,
                      errorBuilder: WidgetUtil.errorImage,
                    )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: AutoSizeText(
                    info.name,
                    style: StyleUtil.textLargeBlack,
                    maxLines: 1,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCallNum(int num) {
    return Visibility(
      visible: (num > 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: AutoSizeText.rich(
          maxFontSize: 40,
          TextSpan(
            children: [
              const TextSpan(text: '今天已打 '),
              TextSpan(
                text: num.toString(),
                style: const TextStyle(color: Colors.red),
              ),
              const TextSpan(text: ' 次'),
            ],
          ),
          style: StyleUtil.textLargeBlack,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildButton(
    PhoneInfo? info,
    Color color,
    IconData iconData, {
    double? w,
    double? h,
  }) {
    return GestureDetector(
      onTap: () {
        if (info != null) {
          if (iconData == CupertinoIcons.videocam_fill) {
            _wechat(info);
          } else if (iconData == CupertinoIcons.phone_down_fill) {
            _hangUp();
          } else {
            _call(info);
          }
        }
        SmartDialog.dismiss(status: SmartStatus.allDialog);
      },
      onLongPress: () {
        // 长按红色按钮：取消进行中的微信拨打会话。
        if (iconData == CupertinoIcons.phone_down_fill) {
          _cancelWvc();
        }
      },
      child: Card(
        color: color,
        child: SizedBox(
          width: w ?? double.infinity,
          height: h ?? double.infinity,
          child: Icon(iconData, color: Colors.white70, size: 68),
        ),
      ),
    );
  }

  Widget _buildDialogLandscape(PhoneInfo info, int num, bool wechat) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (info.wechat.isNotEmpty && wechat) {
                      _wechat(info);
                    } else {
                      _call(info);
                    }
                    SmartDialog.dismiss(status: SmartStatus.allDialog);
                  },
                  child: Card(color: info.color(), child: _picture(info)),
                ),
              ),
              Column(
                children: [
                  Visibility(
                    visible: info.wechat.isNotEmpty && wechat,
                    child: Expanded(
                      child: _buildButton(
                        info,
                        Colors.blue,
                        CupertinoIcons.videocam_fill,
                        w: 180,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildButton(
                      info,
                      Colors.green,
                      CupertinoIcons.phone_fill,
                      w: 180,
                    ),
                  ),
                  Expanded(
                    child: _buildButton(
                      info,
                      Colors.red,
                      CupertinoIcons.phone_down_fill,
                      w: 180,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildCallNum(num),
      ],
    );
  }

  Widget _buildDialogPortrait(PhoneInfo info, int num, bool wechat) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (info.wechat.isNotEmpty && wechat) {
                _wechat(info);
              } else {
                _call(info);
              }
              SmartDialog.dismiss(status: SmartStatus.allDialog);
            },
            child: Card(color: info.color(), child: _picture(info)),
          ),
        ),
        _buildCallNum(num),
        Visibility(
          visible: info.wechat.isNotEmpty && wechat,
          child: _buildButton(
            info,
            Colors.blue,
            CupertinoIcons.videocam_fill,
            h: 68,
          ),
        ),
        _buildButton(info, Colors.green, CupertinoIcons.phone_fill, h: 68),
        _buildButton(info, Colors.red, CupertinoIcons.phone_down_fill, h: 68),
      ],
    );
  }

  void _showDialog(PhoneInfo info) async {
    TtsVibrationUtil().speak(info);
    TtsVibrationUtil().vibration();
    final int num = await DbUtil().getTodayNum(info.phone);
    await _refreshWechatReady();
    bool wechat = _wechatReady;
    await SmartDialog.show(
      builder: (context) {
        double w = MediaQuery.of(context).size.width / 1.25;
        double h = w * 1.68;
        h = min(h, MediaQuery.of(context).size.height);
        if (MediaQuery.of(context).orientation == Orientation.landscape) {
          h = MediaQuery.of(context).size.height / 1.25;
          w = h * 1.68;
          w = min(w, MediaQuery.of(context).size.width);
        }
        Widget child =
            MediaQuery.of(context).orientation == Orientation.portrait
            ? _buildDialogPortrait(info, num, wechat)
            : _buildDialogLandscape(info, num, wechat);
        child = child.animate().shimmer(
          duration: 1500.ms,
          color: Colors.white.withValues(alpha: 0.4),
        );

        return Container(
          constraints: BoxConstraints(maxWidth: w, maxHeight: h),
          decoration: BoxDecoration(
            color: Colors.white60,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(15),
          child: child,
        );
      },
      maskWidget: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black54,
        ),
      ),
    );
  }

  Future<void> _call(PhoneInfo info) async {
    DbUtil().addRecord(info);

    bool open = false;
    if (Platform.isAndroid) {
      if (await Permission.phone.request().isGranted) {
        // Either the permission was already granted before or the user just granted it.
        AndroidIntent intent = AndroidIntent(
          action: 'android.intent.action.CALL',
          data: 'tel:${info.phone}',
        );
        await intent.launch();
        open = true;
      }
    }
    if (!open) {
      Uri url = Uri(scheme: 'tel', path: info.phone);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        WidgetUtil.showToast('拨号失败');
      }
    }
  }

  Future<void> _wechat(PhoneInfo info) async {
    if (!Platform.isAndroid) {
      WidgetUtil.showToast('暂不支持');
      return;
    }
    if (info.wechat.trim().isEmpty) {
      WidgetUtil.showToast('请先为联系人填写微信备注');
      return;
    }

    final ok = await WechatUtil().video(
      info,
      onStatus: WidgetUtil.showToast,
    );
    if (ok) {
      DbUtil().addWechatRecord(info);
      await _refreshWechatReady();
    } else {
      // 未校准 / 无权限时引导去权限页
      final progress = await WechatUtil().calibrationProgress();
      if (!progress.readyForVideo && mounted) {
        WidgetUtil.showToast('请先完成微信坐标校准');
      }
      await _refreshWechatReady();
    }
  }

  Future<void> _hangUp() async {
    if (!Platform.isAndroid) {
      WidgetUtil.showToast('暂不支持');
      return;
    }
    final ok = await WechatUtil().hangUp();
    WidgetUtil.showToast(ok ? '已尝试挂断' : '挂断失败，请先校准挂断点');
    SmartDialog.dismiss(status: SmartStatus.allDialog);
  }

  Future<void> _cancelWvc() async {
    if (!Platform.isAndroid) {
      WidgetUtil.showToast('暂不支持');
      return;
    }
    final ok = await WechatUtil().cancel();
    WidgetUtil.showToast(ok ? '已取消拨打' : '当前没有进行中的拨打');
    SmartDialog.dismiss(status: SmartStatus.allDialog);
  }
}
