// Author: Ujwal N K
// Created: 2026.06.29
// DashScreen - Incoming call screen

import 'package:flutter/material.dart';

import '../../bridges/telephony_bridge.dart';
import '../../commons/dash_action.dart';
import '../../navigation_graph.dart';

const String kDisplayValueKey = "display_contact";

Future<List<DashAction>> buildCallAnswerActions() async {
  return [
    DashAction(label: NavigationGraph.instance.data[kDisplayValueKey], icons: [], action: () {}),
    DashAction(
      label: "Answer",
      icons: [Icons.call_rounded],
      action: () async {
        await TelephonyBridge.answerCall();
        NavigationGraph.instance.goTo(CurrentPage.callActPage);
      },
    ),
    DashAction(
      label: "Decline",
      icons: [Icons.call_end_rounded],
      action: () async {
        await TelephonyBridge.endCall();
        NavigationGraph.instance.goTo(CurrentPage.homePage);
      },
    ),
    DashAction(
      label: "Ignore",
      icons: [Icons.notifications_off_rounded],
      action: () async {
        await TelephonyBridge.silenceCall();
        NavigationGraph.instance.goTo(CurrentPage.homePage);
      },
    ),
  ];
}
