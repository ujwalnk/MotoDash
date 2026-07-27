// Author: Ujwal N K
// Created:
// DashScreen - Home screen

import 'package:flutter/material.dart';
import 'package:moto_dash/bridges/assistant_bridge.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/commons/permission_check.dart';
import 'package:moto_dash/navigation_graph.dart';

Future<List<DashAction>> buildHomeActions() async {
  return [
    if (await PermissionCheck.phone &&
        await PermissionCheck.callLog() &&
        ConfigProvider.phoneFavContactNames.isNotEmpty)
      DashAction(
        label: 'Phone',
        icons: [Icons.phone_rounded],
        action: () => NavigationGraph.instance.goTo(CurrentPage.callNavPage),
      ),
    DashAction(
      label: 'Music',
      icons: [Icons.music_note_rounded],
      action: () => NavigationGraph.instance.goTo(CurrentPage.musicPage),
    ),
    DashAction(label: 'Assistant', icons: [Icons.assistant_rounded], action: () => AssistantBridge.launch()),
    DashAction(
      label: 'Volume',
      icons: [Icons.volume_up_rounded],
      action: () => NavigationGraph.instance.goTo(CurrentPage.volumePage),
    ),
  ];
}
