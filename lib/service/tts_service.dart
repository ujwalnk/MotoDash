import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  bool _enabled = true;

  TtsService() {
    _tts.setSpeechRate(0.45);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
    _tts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text) async {
    if (!_enabled) return;

    await _tts.stop(); // Prevent overlap
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  void setEnabled(bool value) {
    _enabled = value;
  }

  void dispose() {
    _tts.stop();
  }
}
