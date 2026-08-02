// Author: Ujwal N K
// Created: 2026, Mar 22
// Description: Root screen for MotoDash

/*
 *
 * This intentionally does not model each dashboard page as an independent Widget, StatefulWidget, or route.
 *
 * Instead, every page is represented by a lightweight page controller that produces a List<DashAction>, which is then
 * rendered by this single root screen.
 *
 * This architecture was chosen because the dashboard is not purely UI-driven. The active DashActions must remain
 * accessible even when the display is off, allowing external input sources (Bluetooth remotes, hardware buttons,
 * sensors, voice commands, notification actions, etc.) to interact with the currently active page without depending
 * on the widget tree.
 *
 * Keeping a single rendering surface provides several advantages:
 *
 * • A single source of truth for the active DashActions.
 * • UI and non-UI input mechanisms operate on the exact same actions.
 * • No widget or route transitions between dashboard pages.
 * • Lower rebuild overhead and reduced widget complexity.
 * • Page-specific lifecycle (init/terminate) can still be managed without coupling business logic to Flutter widgets.
 *
 * In this architecture, pages represent application state and behavior rather than screens. The root screen is only
 * responsible for rendering the current page's DashActions, while the page itself owns its lifecycle and domain logic.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moto_dash/bridges/display_bridge.dart';
import 'package:moto_dash/commons/config_provider.dart' show ConfigProvider;
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/dash_action.dart' show DashAction;
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/controllers/ble_hid_intent_detector/ble_intent_detector.dart';
import 'package:moto_dash/controllers/bt_hid_intent_detector/bt_intent_detector.dart';
import 'package:moto_dash/controllers/magnet_intent_detector.dart';
import 'package:moto_dash/navigation_graph.dart' show NavigationGraph;
import 'package:moto_dash/screens/pages/page_map.dart' show menuActions;
import 'package:moto_dash/services/adaptive_volume_service.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends SplitScreenState<RootScreen> {
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
  void initState() {
    super.initState();

    if (ConfigProvider.dashboardStatusBar) {
      BleIntentDetector().addListener(() => setState(() {}));
      BtIntentDetector().addListener(() => setState(() {}));
      MagnetIntentService().addListener(() => setState(() {}));
      AdaptiveVolumeService().addListener(() => setState(() {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NavigationGraph.instance,
      builder: (context, _) {
        // Reset the screen timer
        if (ConfigProvider.screenSaverEnabled) _resetScreenSaverTimer();

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
          future: builder.buildActions(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final items = snapshot.data!;

            return Scaffold(
              backgroundColor: backgroundColor,
              body: Column(
                children: [
                  if (ConfigProvider.dashboardStatusBar) sectionTopBar(),
                  sectionBody(widgets, items, context, navigator),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Stream<DateTime> get clockStream async* {
    while (true) {
      yield DateTime.now();

      final now = DateTime.now();
      await Future.delayed(Duration(minutes: 1, seconds: -now.second, milliseconds: -now.millisecond));
    }
  }

  Widget sectionTopBar() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: backgroundColor),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_iconWidget(), _timeStreamWidget()]),
    );
  }

  Row _iconWidget() {
    return Row(
      children: [
        if (BleIntentDetector.isInitialized || BtIntentDetector.isInitialized)
          Icon(Icons.bluetooth, color: fontColor, size: 16),
        SizedBox(width: 6),
        if (AdaptiveVolumeService.isInitialized) Icon(Icons.speed_rounded, color: fontColor, size: 16),
        SizedBox(width: 6),
        if (MagnetIntentService.isInitialized) Icon(Icons.sensors, color: fontColor, size: 16),
      ],
    );
  }

  StreamBuilder<DateTime> _timeStreamWidget() {
    return StreamBuilder<DateTime>(
      stream: clockStream,
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        return Text(
          MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(snapshot.data!),
            alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
          ),
          style: TextStyle(color: fontColor, fontSize: 12),
        );
      },
    );
  }

  Widget sectionBody(DashWidgets widgets, List<DashAction> items, BuildContext context, NavigationGraph navigator) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeInQuint,
          switchOutCurve: Curves.easeOutQuint,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: SizedBox(
            key: ValueKey(navigator.page),
            child: widgets.dashView(isSplitScreen, [
              ...items.map((item) => widgets.dashCardAction(item, context, items.length + (navigator.canPop ? 1 : 0))),
              if (navigator.canPop)
                widgets.dashCardAction(
                  DashAction(label: "Back", icons: [Icons.undo_rounded], action: () => navigator.pop()),
                  context,
                  items.length + 1,
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
