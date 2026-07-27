// Author: Ujwal N K
// Created: 2026, Mar 22
// DashScreen - Call navigation screen

import 'package:flutter/material.dart' show Icons;
import 'package:moto_dash/commons/dash_action.dart' show DashAction;
import 'package:moto_dash/commons/permission_check.dart';

import '../../navigation_graph.dart';

Future<List<DashAction>> buildCallNavActions() async {
  return [
    if (await PermissionCheck.callLog())
      DashAction(
        label: "Call Log",
        icons: [Icons.history_rounded],
        action: () => NavigationGraph.instance.goTo(CurrentPage.callLogPage),
      ),
    // TODO: Check for favorite contacts here
    DashAction(
      label: "Favorites",
      icons: [Icons.star_rounded],
      action: () => NavigationGraph.instance.goTo(CurrentPage.callFavPage),
    ),
  ];
}
