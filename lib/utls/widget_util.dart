import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:call/utls/style_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'flavor_util.dart';

class WidgetUtil {
  static Future<void> confirmPopup(
    String msg, {
    GestureTapCallback? onTap,
    String? buttonText,
    Color buttonColor = Colors.green,
  }) async {
    await SmartDialog.show(
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints.loose(const Size(280, 500)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AutoSizeText(
                    msg,
                    style: StyleUtil.textLargeBlack,
                    maxLines: msg.length ~/ 8 + 1,
                  ),
                  GestureDetector(
                    onTap: () {
                      SmartDialog.dismiss(status: SmartStatus.allDialog);
                      if (onTap != null) {
                        onTap();
                      }
                    },
                    child: Card(
                      color: buttonColor,
                      child: SizedBox(
                        height: 60,
                        child: Center(
                          child: AutoSizeText(
                            buttonText ?? '确定',
                            style: StyleUtil.buttonTextStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> showToast(String msg) async {
    SmartDialog.showToast(
      msg,
      animationType: SmartAnimationType.centerScale_otherSlide,
      builder: (context) {
        return Card(
          color: Colors.grey.shade800,
          margin: const EdgeInsets.all(40),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AutoSizeText(
              msg,
              style: StyleUtil.textLargeWhite,
              maxFontSize: 30,
            ),
          ),
        );
      },
    );
  }

  static Future<void> showLoading(String msg) async {
    return SmartDialog.showLoading(msg: msg);
  }

  static Future<void> hideLoading() async {
    return SmartDialog.dismiss(status: SmartStatus.loading);
  }

  static Widget titleText(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: AutoSizeText(title, style: StyleUtil.textStyle),
    );
  }

  static Widget photoImageIcon(
    String photoPath, [
    int size = 50,
    Color? color,
  ]) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: photoPath.isNotEmpty
          ? photoPath.contains('/')
                ? Image.file(
                    File(photoPath),
                    fit: BoxFit.cover,
                    width: size.toDouble(),
                    height: size.toDouble(),
                    cacheWidth: size * 3,
                    cacheHeight: size * 3,
                    errorBuilder: WidgetUtil.errorImageSmall,
                  )
                : Image.asset(
                    'assets/${FlavorUtil.flavor()}/$photoPath',
                    fit: BoxFit.cover,
                    width: size.toDouble(),
                    height: size.toDouble(),
                    cacheWidth: size * 3,
                    cacheHeight: size * 3,
                    errorBuilder: WidgetUtil.errorImageSmall,
                  )
          : Container(
              color: color ?? Colors.grey.shade600,
              width: size.toDouble(),
              height: size.toDouble(),
              child: Center(
                child: Icon(CupertinoIcons.person_solid, size: size / 1.2),
              ),
            ),
    );
  }

  static Widget errorImage(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      color: Colors.grey,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.xmark_circle, size: 40, color: Colors.red),
            Text(
              '图片加载失败',
              style: StyleUtil.textStyle.copyWith(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  static Widget errorImageSmall(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      color: Colors.grey,
      child: SizedBox(
        width: 50,
        height: 50,
        child: Center(
          child: Icon(CupertinoIcons.xmark_circle, size: 30, color: Colors.red),
        ),
      ),
    );
  }
}
