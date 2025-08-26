/// 语音播报设置
class VoiceVibrationSet {
  static final defaultVoiceVibrationSet = VoiceVibrationSet(
    true,
    100,
    40,
    100,
    true,
    100,
    125,
  );

  VoiceVibrationSet(
    this.voice,
    this.volume,
    this.rate,
    this.pitch,
    this.vibration,
    this.duration,
    this.amplitude,
  );

  final int id = 0;

  bool voice;

  int volume;

  int rate;

  int pitch;

  bool vibration;

  int duration;

  int amplitude;

  Map<String, dynamic> toMap() {
    return {
      'ID': 0,
      'VOICE': voice ? 1 : 0,
      'VOLUME': volume,
      'RATE': rate,
      'PITCH': pitch,
      'VIBRATION': vibration ? 1 : 0,
      'DURATION': duration,
      'AMPLITUDE': amplitude,
    };
  }

  double getVolume() {
    return volume / 100.0;
  }

  void setVolume(double v) {
    volume = (v * 100).toInt();
  }

  double getRate() {
    return rate / 100.0;
  }

  void setRate(double r) {
    rate = (r * 100).toInt();
  }

  double getPitch() {
    return pitch / 100.0;
  }

  void setPitch(double p) {
    pitch = (p * 100).toInt();
  }

  double getDuration() {
    return duration / 1000.0;
  }

  void setDuration(double d) {
    duration = (d * 1000).toInt();
  }

  double getAmplitude() {
    double tmp = amplitude / 255.0;
    return tmp > 0.0 ? tmp : 0.0;
  }

  void setAmplitude(double a) {
    int tmp = (a * 255).toInt();
    amplitude = tmp >= 1 ? tmp : -1;
  }
}
