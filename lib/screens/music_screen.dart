import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moto_dash/commons/dash_action.dart';

const MethodChannel _channel = MethodChannel('assistant.launcher');

Future<List<DashAction>> buildMusicActions() async {
  return [
    DashAction(
      label: 'Previous',
      icons: [Icons.skip_previous_rounded],
      action: () async => await _channel.invokeMethod('previousTrack'),
    ),
    DashAction(
      label: 'Play Pause',
      icons: [Icons.play_arrow_rounded, Icons.pause_rounded],
      action: () async => await _channel.invokeMethod('togglePlayPause'),
    ),
    DashAction(
      label: 'Next',
      icons: [Icons.skip_next_rounded],
      action: () async => await _channel.invokeMethod('nextTrack'),
    ),
  ];
}
