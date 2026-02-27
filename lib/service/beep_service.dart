// Author: Ujwal N K
// Created On: 2026, Feb 27

import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart' as audio_session;

class BeepService {
  static final BeepService _instance = BeepService._internal();
  factory BeepService() => _instance;
  BeepService._internal();

  bool beepEnabled = true;

  final AudioPlayer _player = AudioPlayer();

  Future<void> init() async {
    final session = await audio_session.AudioSession.instance;
    await session.configure(
      audio_session.AudioSessionConfiguration(
        avAudioSessionCategory: audio_session.AVAudioSessionCategory.ambient,
        avAudioSessionCategoryOptions:
            audio_session.AVAudioSessionCategoryOptions.mixWithOthers,
        androidAudioAttributes: const audio_session.AndroidAudioAttributes(
          contentType: audio_session.AndroidAudioContentType.sonification,
          usage: audio_session.AndroidAudioUsage.assistanceSonification,
        ),
        androidAudioFocusGainType:
            audio_session.AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ),
    );

    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(1.0);
  }

  Future<void> beep() async {
    if (!beepEnabled) return;
    await _player.play(AssetSource('beep.mp3'), volume: 1.0);
  }

  void dispose() {
    _player.dispose();
  }
}
