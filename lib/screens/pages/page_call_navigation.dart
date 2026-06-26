// Author: Ujwal N K
// Created: 2026, Mar 22
// DashScreen - Call navigation screen

import 'package:flutter/material.dart' show Icons;
import 'package:moto_dash/commons/dash_action.dart' show DashAction;

import '../../navigation_graph.dart';

Future<List<DashAction>> buildCallNavActions() async {
  return [
    DashAction(
      label: "Call Log",
      icons: [Icons.history_rounded],
      action: () => NavigationGraph.instance.goTo(CurrentPage.callLogPage),
    ),
    DashAction(
      label: "Favorites",
      icons: [Icons.star_rounded],
      action: () => NavigationGraph.instance.goTo(CurrentPage.callFavPage),
    ),
  ];
}
