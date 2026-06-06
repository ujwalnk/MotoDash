// Author: Ujwal N K
// Created: 2026.06.05
// Active call handler screen - call disconnect & mute mic options

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/service/native_bridge.dart';

import '../navigation_graph.dart';

Future<List<DashAction>> buildCallActiveActions() async {
  final call = CallBridge();

  return [
    DashAction(
      label: "End call",
      icons: [Icons.call_end_rounded],
      action: () async {
        await call.endCall();
        NavigationGraph.instance.goTo(CurrentPage.homePage);
      },
    ),
  ];
}
