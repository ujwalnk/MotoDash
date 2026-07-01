// Author: Ujwal N K
// Created:
// Text to speech service for reading out selected menu item.

import 'package:audio_session/audio_session.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:moto_dash/bridges/assistant_bridge.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:phone_state/phone_state.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  AudioSession? _session;
  bool _isCallActive = false;

  /// Creates a [TtsService] instance and initializes audio session and call-state handling.
  ///
  /// Starts asynchronous initialization via [_init], subscribes to [PhoneState.stream] to keep [_isCallActive]
  /// synchronized with the current call status, and registers a completion handler on [_tts] that deactivates
  /// [_session] when speech playback finishes.
  ///
  /// Side effects:
  /// - Subscribes to [PhoneState.stream].
  /// - Registers a completion handler via [_tts.setCompletionHandler].
  ///
  /// State mutations:
  /// - Updates [_isCallActive] in response to phone state changes.
  /// - Assigns [_session] asynchronously via [_init].
  ///
  /// External variables modified: None.
  ///
  /// Navigation calls: None.
  ///
  /// Async behavior:
  /// - Invokes [_init] without awaiting its completion.
  /// - The registered completion handler asynchronously deactivates [_session]
  ///   when TTS playback completes.
  TtsService() {
    _init();

    PhoneState.stream.listen((state) {
      _isCallActive = state.status == PhoneStateStatus.CALL_STARTED;
    });

    _tts.setCompletionHandler(() async {
      await _session?.setActive(false);
    });
  }

  /// Initializes [_session] with the application's shared [AudioSession] instance.
  ///
  /// Side effects: None.
  ///
  /// State mutations:
  /// - Assigns the retrieved [AudioSession] instance to [_session].
  ///
  /// External variables modified: None.
  ///
  /// Navigation calls: None.
  ///
  /// Async behavior:
  /// - Awaits retrieval of the shared [AudioSession] instance.
  Future<void> _init() async {
    _session = await AudioSession.instance;
  }

  /// Configures [_session] for text-to-speech playback when no call is active.
  ///
  /// Applies an [AudioSessionConfiguration] optimized for assistant-style speech output. The configuration requests
  /// transient audio focus and allows other media playback to be paused while TTS is active.
  ///
  /// Side effects:
  /// - Updates the audio session configuration of [_session].
  ///
  /// State mutations: None.
  ///
  /// External variables modified: None.
  ///
  /// Navigation calls: None.
  ///
  /// Async behavior:
  /// - Awaits completion of the audio session reconfiguration.
  /// - Requires [_session] to be initialized.
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

  /// Configures [_session] for text-to-speech playback during an active call.
  ///
  /// Applies an [AudioSessionConfiguration] that routes speech through a voice-communication audio context while
  /// allowing other audio sources to be ducked rather than paused. The configuration is intended to share the call
  /// audio stream and permit TTS playback while a call is in progress.
  ///
  /// Side effects:
  /// - Updates the audio session configuration of [_session].
  ///
  /// State mutations: None.
  ///
  /// External variables modified: None.
  ///
  /// Navigation calls: None.
  ///
  /// Async behavior:
  /// - Awaits completion of the audio session reconfiguration.
  /// - Requires [_session] to be initialized.
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
        // TTS enabled during call
        androidWillPauseWhenDucked: false,
      ),
    );
  }

  /// Speaks the provided [text] using the configured text-to-speech engine.
  ///
  /// Any in-progress speech is stopped via [_tts] before starting a new utterance. If
  /// [ConfigProvider.riderGesturesTtsOnBtOnly] is enabled and [AssistantBridge.isBluetoothConnected] returns `false`,
  /// the method exits without speaking.
  ///
  /// Configures the audio session for either call or media playback using [_configureForCall] or [_configureForMedia]
  /// based on [_isCallActive], enables the shared TTS instance, activates [_session], and then invokes [_tts.speak].
  ///
  /// Side effects:
  /// - Stops any active TTS playback via [_tts.stop].
  /// - Reconfigures the audio session.
  /// - Activates [_session].
  /// - Initiates TTS playback via [_tts.speak].
  ///
  /// State mutations: None.
  ///
  /// External variables modified: None.
  ///
  /// Navigation calls: None.
  ///
  /// Async behavior:
  /// - Awaits audio session reconfiguration and activation.
  /// - Awaits Bluetooth connectivity checks when required.
  /// - Awaits TTS stop and speech operations.
  /// - Returns early if Bluetooth-only TTS is enabled and no Bluetooth device is connected.
  Future<void> speak(String text) async {
    // Stop if any previously spoken - mid speak session
    await _tts.stop();

    // TTS based on bluetooth only - user setting
    if (ConfigProvider.riderGesturesTtsOnBtOnly && (!await AssistantBridge.isBluetoothConnected())) {
      return;
    }

    // Based on call, change the tts media channel
    if (_isCallActive) {
      await _configureForCall();
    } else {
      await _configureForMedia();
    }

    await _tts.setSharedInstance(true);
    await _session?.setActive(true);

    await _tts.speak(text);
  }

  /// Stops any active text-to-speech playback and deactivates [_session].
  ///
  /// Side effects:
  /// - Stops TTS playback via [_tts.stop].
  /// - Deactivates [_session].
  ///
  /// State mutations:None.
  ///
  /// External variables modified: None.
  ///
  /// Navigation calls: None.
  ///
  /// Async behavior:
  /// - Awaits completion of the TTS stop operation.
  /// - Awaits audio session deactivation when [_session] is available.
  Future<void> stop() async {
    await _tts.stop();
    await _session?.setActive(false);
  }
}
