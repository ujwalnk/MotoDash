// Author: Ujwal N K
// Created On: 2026.02.27

import 'package:audio_session/audio_session.dart' as audio_session;
import 'package:audioplayers/audioplayers.dart';

/// Provides centralized playback of a short notification beep using a shared [AudioPlayer] instance.
///
/// Configures the platform audio session in [init] to allow sonification audio to mix with other active audio sources
/// and initializes [_player] playback settings. The [beep] method plays the bundled `beep.mp3` asset when
/// [beepEnabled] is `true`.
///
/// Side effects:
/// - Configures the system audio session via [audio_session.AudioSession.configure].
/// - Plays audio through [_player].
/// - Releases audio resources in [dispose].
///
/// State mutations:
/// - Updates [_player] configuration in [init].
///
/// External variables modified: None.
///
/// Async behavior:
/// - [init] performs asynchronous audio session and player configuration.
/// - [beep] asynchronously starts playback of the audio asset.
/// - Playback requests are ignored when [beepEnabled] is `false`.
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
        avAudioSessionCategoryOptions: audio_session.AVAudioSessionCategoryOptions.mixWithOthers,
        androidAudioAttributes: const audio_session.AndroidAudioAttributes(
          contentType: audio_session.AndroidAudioContentType.sonification,
          usage: audio_session.AndroidAudioUsage.assistanceSonification,
        ),
        androidAudioFocusGainType: audio_session.AndroidAudioFocusGainType.gainTransientMayDuck,
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
