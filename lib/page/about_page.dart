import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../utls/flavor_util.dart';
import '../utls/style_util.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<Map<String, String>> _initData() async {
    Map<String, String> info = {};
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      info['品牌'] = androidInfo.brand;
      info['设备'] = androidInfo.product;
      info['型号'] = androidInfo.model;
      info['系统'] = androidInfo.version.release;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      info['系统'] = iosDeviceInfo.systemVersion;
      info['型号'] = iosDeviceInfo.model;
      info['标识'] = iosDeviceInfo.utsname.machine;
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    info['名称'] = packageInfo.appName;
    info['版本'] = packageInfo.version;
    info['构建'] = packageInfo.buildNumber;

    info['风格'] = FlavorUtil.flavor();

    return info;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于信息'),
      ),
      body: FutureBuilder(
        future: _initData(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, String>> snapshot) {
          return Visibility(
            visible: (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData &&
                snapshot.data!.isNotEmpty),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (String key in snapshot.data?.keys ?? [])
                  ListTile(
                    title: AutoSizeText(
                      key,
                      style: StyleUtil.textStyle,
                    ),
                    trailing: AutoSizeText(
                      snapshot.data![key] ?? '',
                      style: StyleUtil.textStyle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
