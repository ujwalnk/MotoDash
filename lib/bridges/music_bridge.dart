// Author: Ujwal N K
// Created: 2026.06.29
// Kotlin bridge for music playback control

import 'package:flutter/services.dart';

abstract class MusicBridge {
  // TODO: Change channel name
  static const MethodChannel _channel = MethodChannel("assistant.launcher");

  static Future<void> previous() async => await _channel.invokeMethod<void>("previousTrack");

  static Future<void> next() async => await _channel.invokeMethod<void>("nextTrack");

  static Future<void> playPause() async => await _channel.invokeMethod<void>("togglePlayPause");
}
