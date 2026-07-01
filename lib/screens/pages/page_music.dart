// Author: Ujwal N K
// Created:
// DashScreen - Music controls

import 'package:flutter/material.dart';
import 'package:moto_dash/bridges/music_bridge.dart';
import 'package:moto_dash/commons/dash_action.dart';

/// Builds the set of dashboard actions for controlling media playback.
///
/// Returns a list of [DashAction] objects that invoke media transport controls through [_channel]. The actions
/// trigger the `previousTrack`, `togglePlayPause`, and `nextTrack` platform methods.
///
/// Side effects:
/// Sends method channel requests through [_channel] to the native platform.
///
/// State mutations: None.
///
/// External variables modified: None.
///
/// Navigation: None.
///
/// Async behavior:
/// Returns a [Future] that completes with the constructed list of [DashAction] objects. Each action callback performs
/// asynchronous method channel invocation when executed.
Future<List<DashAction>> buildMusicActions() async {
  return [
    DashAction(label: 'Previous', icons: [Icons.skip_previous_rounded], action: MusicBridge.previous),
    DashAction(
      label: 'Play Pause',
      icons: [Icons.play_arrow_rounded, Icons.pause_rounded],
      action: MusicBridge.playPause,
    ),
    DashAction(label: 'Next', icons: [Icons.skip_next_rounded], action: MusicBridge.next),
  ];
}
