import 'package:call/utls/db_util.dart';
import 'package:call/utls/voice_vibration_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'page/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DbUtil().init().then((_) {
    TtsVibrationUtil().init();
  });

  runApp(const CallApp());
}

class CallApp extends StatelessWidget {
  const CallApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1677FF);

    return MediaQuery.withNoTextScaling(
      child: MaterialApp(
        title: '打电话',
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryColor,
            brightness: Brightness.dark,
            dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
          ),
        ),
        home: const HomePage(),
        navigatorObservers: [FlutterSmartDialog.observer],
        builder: FlutterSmartDialog.init(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('zh', 'CN')],
        locale: const Locale('zh', 'CN'),
      ),
    );
  }
}
