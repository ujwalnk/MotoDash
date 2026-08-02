// Author: Ujwal N K
// Created: 2026, Mar 22
// DashScreen - Call navigation screen

import 'package:flutter/material.dart' show Icons;
import 'package:moto_dash/commons/dash_action.dart' show DashAction, DashNavigation;
import 'package:moto_dash/commons/dash_page.dart';
import 'package:moto_dash/commons/permission_check.dart';

import '../../navigation_graph.dart';

class PageCallNavigation extends DashPage {
  @override
  Future<List<DashAction>> buildActions() async {
    return [
      if (await PermissionCheck.callLog())
        DashNavigation(
          label: "Call Log",
          icons: [Icons.history_rounded],
          action: () => NavigationGraph.instance.goTo(CurrentPage.callLogPage),
        ),
      // TODO: Check for favorite contacts here
      DashNavigation(
        label: "Favorites",
        icons: [Icons.star_rounded],
        action: () => NavigationGraph.instance.goTo(CurrentPage.callFavPage),
      ),
    ];
  }
}
