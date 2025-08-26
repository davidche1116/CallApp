import 'package:call/data/phone_info.dart';
import 'package:call/utls/db_util.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

import '../data/voice_vibration_set.dart';

class TtsVibrationUtil {
  factory TtsVibrationUtil() => _instance;

  TtsVibrationUtil._internal();

  static final TtsVibrationUtil _instance = TtsVibrationUtil._internal();

  late final FlutterTts _tts;

  late VoiceVibrationSet _set;

  /// 不同手机声音、音调、语速不同，可自行调整
  /// 手机没有自带tts或自带的不好听可以下载安装讯飞tts
  Future<void> init() async {
    _tts = FlutterTts();

    _set = await DbUtil().getVoiceVibration();

    /// 设置语言
    await _tts.setLanguage("zh-CN");

    await setVoice(_set);
  }

  /// 文字[text】转语音并播放
  Future<void> speak(PhoneInfo info) async {
    if (_set.voice) {
      String text = info.voice;
      if (text.isEmpty) {
        text = info.name;
      }
      text = text.replaceAll(' ', '');

      if (text.isNotEmpty) {
        await _tts.speak(text);
      }
    }
  }

  Future<void> setVoice(VoiceVibrationSet set) async {
    _set = set;

    /// 设置音量
    await _tts.setVolume(set.getVolume());

    /// 设置语速
    await _tts.setSpeechRate(set.getRate());

    /// 音调
    await _tts.setPitch(set.getPitch());
  }

  Future<void> vibration() async {
    if (_set.vibration) {
      Vibration.vibrate(duration: _set.duration, amplitude: _set.amplitude);
    }
  }
}
