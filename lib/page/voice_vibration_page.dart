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
            icon: const Icon(CupertinoIcons.tray),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingCard(
            title: '语音设置',
            children: [
              _buildSwitchTile(
                title: '语音开关',
                value: _voiceSet.voice,
                onChanged: (value) {
                  setState(() {
                    _voiceSet.voice = value;
                  });
                },
              ),
              _buildSliderTile(
                title: '音量',
                value: _voiceSet.getVolume(),
                onChanged: (value) {
                  setState(() {
                    _voiceSet.setVolume(value);
                  });
                },
              ),
              _buildSliderTile(
                title: '语速',
                value: _voiceSet.getRate(),
                onChanged: (value) {
                  setState(() {
                    _voiceSet.setRate(value);
                  });
                },
              ),
              _buildSliderTile(
                title: '语调',
                value: _voiceSet.getPitch(),
                min: 0.5,
                max: 2.0,
                onChanged: (value) {
                  setState(() {
                    _voiceSet.setPitch(value);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: '震动设置',
            children: [
              _buildSwitchTile(
                title: '震动开关',
                value: _voiceSet.vibration,
                onChanged: (value) {
                  setState(() {
                    _voiceSet.vibration = value;
                  });
                },
              ),
              _buildSliderTile(
                title: '震动时长',
                value: _voiceSet.getDuration(),
                min: 0.1,
                max: 1.0,
                onChanged: (value) {
                  setState(() {
                    _voiceSet.setDuration(value);
                  });
                },
              ),
              _buildSliderTile(
                title: '震动强度',
                value: _voiceSet.getAmplitude(),
                onChanged: (value) {
                  setState(() {
                    _voiceSet.setAmplitude(value);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    double min = 0.0,
    double max = 1.0,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(title), Text('${(value * 100).toInt()}%')],
          ),
          Slider(value: value, min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }
}
