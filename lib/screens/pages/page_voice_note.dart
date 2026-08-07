// Author: Ujwal N K /w Claude
// Created: 2026.08.07
// PageVoiceNote - single-purpose DashPage: start recording on entry,
// expose one "End Recording" action, save + leave on exit.

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/commons/dash_page.dart';
import 'package:moto_dash/navigation_graph.dart';
import 'package:moto_dash/services/tts_service.dart';
import 'package:moto_dash/services/voice_recorder_service.dart';

class PageVoiceNote extends DashPage {
  @override
  Future<void> init() async {
    final started = await VoiceRecorderService.instance.startRecording();

    // NOTE: adjust this call to match TtsService's real API — this assumes
    // a static/singleton `speak(String)` method, following the same shape
    // as the other bridges/services in the project. Swap in whatever
    // TtsService actually exposes.
    if (started) {
      await TtsService().speak('Voice recording started.');
    } else {
      await TtsService().speak('Could not start recording.');
    }
  }

  @override
  Future<List<DashAction>> buildActions() async {
    return [
      DashAction(
        label: 'End Recording',
        icons: [Icons.stop_circle_rounded],
        action: () async {
          await VoiceRecorderService.instance.stopRecording();
          await NavigationGraph.instance.pop();
        },
      ),
    ];
  }

  @override
  Future<void> terminate() async {
    // Safety net: if the page is left any other way (hardware back button,
    // the root screen's synthetic "Back" action, an incoming call routed
    // through NavigationGraph before CallStateListener's own interruption
    // handling runs, etc.) make sure nothing keeps recording in the
    // background.
    if (VoiceRecorderService.instance.isRecording) {
      await VoiceRecorderService.instance.stopRecording();
    }
  }
}
