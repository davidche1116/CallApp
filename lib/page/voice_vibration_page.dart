import 'package:call/data/voice_vibration_set.dart';
import 'package:call/utls/db_util.dart';
import 'package:call/utls/voice_vibration_util.dart';
import 'package:call/utls/widget_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class VoiceVibrationPage extends StatefulWidget {
  const VoiceVibrationPage({super.key});

  @override
  State<VoiceVibrationPage> createState() => _VoiceVibrationPageState();
}

class _VoiceVibrationPageState extends State<VoiceVibrationPage> {
  VoiceVibrationSet _voiceSet = VoiceVibrationSet.defaultVoiceVibrationSet;

  @override
  void initState() {
    super.initState();

    DbUtil().getVoiceVibration().then((value) {
      setState(() {
        _voiceSet = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语音震动设置'),
        actions: [
          IconButton(
            onPressed: () async {
              await DbUtil().setVoiceVibration(_voiceSet);
              TtsVibrationUtil().setVoice(_voiceSet);
              WidgetUtil.showToast('保存成功');
            },
            icon: const Icon(
              CupertinoIcons.tray,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          WidgetUtil.titleText('语音开关'),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Switch(
                value: _voiceSet.voice,
                onChanged: (bool value) {
                  setState(() {
                    _voiceSet.voice = value;
                  });
                },
              ),
            ],
          ),
          WidgetUtil.titleText('音量'),
          Slider(
            value: _voiceSet.getVolume(),
            onChanged: (value) {
              setState(() {
                _voiceSet.setVolume(value);
              });
            },
          ),
          WidgetUtil.titleText('语速'),
          Slider(
            value: _voiceSet.getRate(),
            onChanged: (value) {
              setState(() {
                _voiceSet.setRate(value);
              });
            },
          ),
          WidgetUtil.titleText('语调'),
          Slider(
            value: _voiceSet.getPitch(),
            min: 0.5,
            max: 2.0,
            onChanged: (value) {
              setState(() {
                _voiceSet.setPitch(value);
              });
            },
          ),
          WidgetUtil.titleText('震动开关'),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Switch(
                value: _voiceSet.vibration,
                onChanged: (bool value) {
                  setState(() {
                    _voiceSet.vibration = value;
                  });
                },
              ),
            ],
          ),
          WidgetUtil.titleText('震动时长'),
          Slider(
            value: _voiceSet.getDuration(),
            min: 0.1,
            max: 1.0,
            onChanged: (value) {
              setState(() {
                _voiceSet.setDuration(value);
              });
            },
          ),
          WidgetUtil.titleText('震动强度'),
          Slider(
            value: _voiceSet.getAmplitude(),
            onChanged: (value) {
              setState(() {
                _voiceSet.setAmplitude(value);
              });
            },
          ),
        ],
      ),
    );
  }
}
