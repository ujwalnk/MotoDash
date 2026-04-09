// Author: Ujwal N K
// Created: 2026, Mar 22

import 'package:flutter/material.dart' show Icons;
import 'package:moto_dash/commons/dash_action.dart' show DashAction;
import 'package:moto_dash/navigation_graph.dart';

Future<List<DashAction>> buildCallNavActions() async {
  return [
    DashAction(
      label: "Favorites",
      icons: [Icons.star_rounded],
      action: () => NavigationGraph.instance.goTo(CurrentPage.callFavPage),
    ),
    DashAction(
      label: "Call Log",
      icons: [Icons.history_rounded],
      action: () => NavigationGraph.instance.goTo(CurrentPage.callLogPage),
    ),
  ];
}
