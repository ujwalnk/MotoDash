// Author: Ujwal N K
// Created: 2026.07.28
// DashScreen - Navigation Controls

import 'package:flutter/material.dart';
import 'package:moto_dash/bridges/navigation_bridge.dart';
import 'package:moto_dash/commons/dash_action.dart';

Future<List<DashAction>> buildNavigationActions() async {
  final directions = await NavigationBridge.getDirections();
  final String? text = [
    directions?["title"],
    directions?["text"],
    directions?["subText"],
  ].whereType<String>().where((s) => s.isNotEmpty).join(". ");

  return [
    if (await NavigationBridge.isNavigationActive()) ...[
      DashAction(label: text ?? "Reread navigation", icons: [Icons.speaker], action: () async {}),
      DashAction(
        label: "Exit navigation",
        icons: [Icons.exit_to_app_rounded],
        action: () => NavigationBridge.exitNavigation(),
      ),
    ],
    DashAction(
      label: "Test location A",
      icons: [],
      action: () async {
        await NavigationBridge.navigateTo(12.8848955, 77.5275458);
      },
    ),
  ];
}
