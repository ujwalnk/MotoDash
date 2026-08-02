// Author: Ujwal N K
// Created: 2026.07.28
// DashScreen - Navigation Controls

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moto_dash/bridges/navigation_bridge.dart';
import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/commons/dash_page.dart';

class PageNavigation extends DashPage {
  /*
 * Navigation state is cached locally and updated through the EventChannel. buildActions() must not perform platform
 * calls; it only converts the current page state into DashActions. This keeps page rebuilding fast and ensures UI
 * updates are driven by events rather than polling.
 */
  Map<String, dynamic>? _directions;

  StreamSubscription<Map<String, dynamic>?>? _subscription;

  @override
  Future<void> init() async {
    if (_subscription != null) return;
    _directions = await NavigationBridge.getDirections();
    refresh();

    _subscription = NavigationBridge.navigationStream.listen((directions) {
      _directions = directions;
      refresh();

      debugPrint("Navigation updated: $_directions");
    });
  }

  @override
  Future<void> terminate() async {
    await _subscription?.cancel();
    _subscription = null;
    _directions = null;
  }

  @override
  Future<List<DashAction>> buildActions() async {
    final directions = _directions;
    final String? text = [
      directions?["title"],
      directions?["text"],
      directions?["subText"],
    ].whereType<String>().where((s) => s.isNotEmpty).join(". ");

    return [
      if (directions != null) ...[
        DashAction(label: text ?? "Reread navigation", icons: [Icons.assistant_navigation], action: () async {}),
        DashAction(
          label: "Exit navigation",
          icons: [Icons.exit_to_app_rounded],
          action: () => NavigationBridge.exitNavigation(),
        ),
      ],
      if (_directions == null) ...[
        DashAction(
          label: "Test location A",
          icons: [],
          action: () async {
            await NavigationBridge.navigateTo(12.8848955, 77.5275458);
          },
        ),
      ],
    ];
  }
}
