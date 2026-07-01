// Author: Ujwal N K
// Created: 2026.06.05
// DashScreen - Active call handler

import 'package:flutter/material.dart';
import 'package:moto_dash/bridges/telephony_bridge.dart';
import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/screens/pages/page_volume.dart';

import '../../navigation_graph.dart';

/// Builds the set of dashboard actions available while a call is active.
///
/// Returns a list of [DashAction] objects for interacting with the current call state. Includes an action that
/// terminates the active call through [TelephonyBridge.endCall] and, volume controls [buildVolumeActions] through navigates
/// to [CurrentPage.homePage] using [NavigationGraph.instance].
///
/// Side effects:
/// Creates a [TelephonyBridge] instance.
///
/// State mutations: None.
///
/// External variables modified: None.
///
/// Navigation:
/// Invokes [NavigationGraph.instance.goTo] to navigate to [CurrentPage.homePage] after the call is ended.
///
/// Async behavior:
/// Returns a [Future] that completes with the constructed list of [DashAction] objects. Awaits [buildVolumeActions]
/// during construction. The end-call action callback performs asynchronous work when invoked.
Future<List<DashAction>> buildCallActiveActions() async {
  // final call = TelephonyBridge();

  return [
    DashAction(
      label: "End call",
      icons: [Icons.call_end_rounded],
      action: () async {
        await TelephonyBridge.endCall();
        NavigationGraph.instance.goTo(CurrentPage.homePage);
      },
    ),
    ...(await buildVolumeActions()),
  ];
}
