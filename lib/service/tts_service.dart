import 'package:flutter_tts/flutter_tts.dart';
import 'package:audio_session/audio_session.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  AudioSession? _session;

  TtsService() {
    _init();

    _tts.setCompletionHandler(() async {
      await _session?.setActive(false);
    });
  }

  Future<void> _init() async {
    _session = await AudioSession.instance;

    await _session!.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.assistant,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient,
        androidWillPauseWhenDucked: true,
      ),
    );
  }

  Future<void> speak(String text) async {
    await _tts.stop();

    await _session?.setActive(true);

    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    await _session?.setActive(false);
  }
}
