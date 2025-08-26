import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:call/utls/flavor_util.dart';
import 'package:call/utls/style_util.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
      body: FutureBuilder<Map<String, String>>(
        future: _initData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double expandRatio =
                        ((constraints.maxHeight - kToolbarHeight) /
                                (200 - kToolbarHeight))
                            .clamp(0.0, 1.0);
                    return FlexibleSpaceBar(
                      background: Container(
                        padding: EdgeInsets.only(top: 40),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(30),
                          ),
                        ),
                        child: Opacity(
                          opacity: expandRatio,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                  image: const DecorationImage(
                                    image: AssetImage('assets/icon/icon.png'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Opacity(
                            opacity: 1 - expandRatio,
                            child: FutureBuilder<PackageInfo>(
                              future: PackageInfo.fromPlatform(),
                              builder: (context, snapshot) {
                                return AutoSizeText(
                                  snapshot.data?.appName ?? '',
                                  style: StyleUtil.textStyle,
                                );
                              },
                            ),
                          ),
                          Row(
                            children: [
                              Opacity(
                                opacity: 1 - expandRatio,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                    image: const DecorationImage(
                                      image: AssetImage('assets/icon/icon.png'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  String key = snapshot.data!.keys.elementAt(index);
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: AutoSizeText(key, style: StyleUtil.textStyle),
                      trailing: AutoSizeText(
                        snapshot.data![key] ?? '',
                        style: StyleUtil.textStyle,
                      ),
                    ),
                  );
                }, childCount: snapshot.data!.length),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          );
        },
      ),
    );
  }
}
