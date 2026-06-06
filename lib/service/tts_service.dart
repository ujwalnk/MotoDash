import 'package:audio_session/audio_session.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:phone_state/phone_state.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  AudioSession? _session;
  bool _isCallActive = false;

  TtsService() {
    _init();

    PhoneState.stream.listen((state) {
      _isCallActive = state.status == PhoneStateStatus.CALL_STARTED;
    });

    _tts.setCompletionHandler(() async {
      await _session?.setActive(false);
    });
  }

  Future<void> _init() async {
    _session = await AudioSession.instance;
  }

  Future<void> _configureForMedia() async {
    await _session!.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.assistant,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient,
        // pauses media
        androidWillPauseWhenDucked: true,
      ),
    );
  }

  Future<void> _configureForCall() async {
    await _session!.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunicationSignalling, // shares call stream
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
        // coexists with call
        androidWillPauseWhenDucked: false,
      ),
    );
  }

  Future<void> speak(String text) async {
    await _tts.stop();

    if (_isCallActive) {
      await _configureForCall();
    } else {
      await _configureForMedia();
    }

    await _tts.setSharedInstance(true);
    await _session?.setActive(true);

    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    await _session?.setActive(false);
  }
}
