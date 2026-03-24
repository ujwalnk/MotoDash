// Author: Ujwal N K
// Created: 2026, Mar 22

import 'package:flutter/material.dart' show Icons;
import 'package:moto_dash/commons/dash_action.dart' show DashAction;

Future<List<DashAction>> buildCallNavActions() async {
  return [
    DashAction(
      label: "Call Log",
      icons: [Icons.history_rounded],
      // TODO: Navigate to Call Log
      action: () {},
    ),
    DashAction(
      label: "Favorites",
      icons: [Icons.star_rounded],
      // TODO: Navigate to Favourites
      action: () {},
    ),
  ];
}
