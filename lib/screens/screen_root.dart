// Author: Ujwal N K
// Created: 2026, Mar 22
// Description: Root screen for MotoDash

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moto_dash/bridges/display_bridge.dart';
import 'package:moto_dash/commons/config_provider.dart' show ConfigProvider;
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/dash_action.dart' show DashAction;
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/navigation_graph.dart' show NavigationGraph;
import 'package:moto_dash/screens/pages/page_map.dart' show menuActions;

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends SplitScreenState<RootScreen> {
  // class _RootScreenState extends State<RootScreen> {
  final Color backgroundColor = ConfigProvider.dashboardBackgroundColor;
  final Color fontColor = ConfigProvider.dashboardFontColor;
  final Color borderColor = ConfigProvider.dashboardBorderColor;
  final double fontSize = ConfigProvider.dashboardFontSize;

  Timer? _screenSaverTimer;

  void _resetScreenSaverTimer() {
    _screenSaverTimer?.cancel();

    _screenSaverTimer = Timer(Duration(seconds: ConfigProvider.screenSaverTimeout.toInt()), () {
      if (!mounted || Navigator.of(context).canPop()) return;

      Navigator.pushNamed(
        context,
        ConfigProvider.screenSaverAnimation ? AppRoutes.screenSaver : AppRoutes.screenSaverBlank,
      ).then((_) {
        // Fires exactly when the screensaver is popped — RootScreen is visible again
        if (mounted) _resetScreenSaverTimer();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NavigationGraph.instance,
      builder: (context, _) {
        // Reset the screen timer
        if (ConfigProvider.screenSaverEnabled) {
          _resetScreenSaverTimer();
        }

        final NavigationGraph navigator = NavigationGraph.instance;
        final widgets = DashWidgets();

        widgets.backgroundColor = backgroundColor;
        widgets.fontColor = fontColor;
        widgets.borderColor = borderColor;

        final builder = menuActions[navigator.page];

        if (builder == null) {
          return const Scaffold(body: Center(child: Text("No page found")));
        }

        return FutureBuilder<List<DashAction>>(
          future: builder(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final items = snapshot.data!;

            return Scaffold(
              backgroundColor: backgroundColor,
              body: Padding(
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                child: widgets.dashView(isSplitScreen, [
                  ...items.map(
                    (item) => widgets.dashCardAction(item, context, items.length + (navigator.canPop ? 1 : 0)),
                  ),

                  if (navigator.canPop)
                    widgets.dashCardAction(
                      DashAction(label: "Back", icons: [Icons.undo_rounded], action: () => navigator.pop()),
                      context,
                      items.length + 1,
                    ),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}
