// Author: Ujwal N K
// Created: 2026, Mar 22
// Description: Root screen for MotoDash

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart' show ConfigProvider;
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/dash_action.dart' show DashAction;
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/menu_actions.dart' show menuActions;
import 'package:moto_dash/navigation_graph.dart' show NavigationGraph;

import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  Color backgroundColor = ConfigProvider.getBackgroundColor;
  Color fontColor = ConfigProvider.getFontColor;
  Color borderColor = ConfigProvider.getBorderColor;

  bool showVolumeTip = true;

  double fontSize = ConfigProvider.getFontSize;

  Timer? _screenSaverTimer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _resetScreenSaverTimer() {
    _screenSaverTimer?.cancel();

    // TODO: Use the screesaver timer from [ConfigProvider] here
    _screenSaverTimer = Timer(const Duration(seconds: 15), () {
      debugPrint("Screensaver triggered");

      if (!mounted) return;

      // Prevent duplicate push
      if (ModalRoute.of(context)?.settings.name == Constants.kPathScreenSaver) {
        return;
      }

      Navigator.pushNamed(context, Constants.kPathScreenSaver);
    });
  }

  @override
  Widget build(BuildContext context) {
    // FIXME: Take care of the page jumping, fix using animation - AnimatedSwitcher
    return AnimatedBuilder(
      animation: NavigationGraph.instance,
      builder: (context, _) {
        // Reset the screen timer
        _resetScreenSaverTimer();

        final navigator = NavigationGraph.instance;
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
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final items = snapshot.data!;

            debugPrint(
              "Is Popable ${navigator.page} Screen: ${navigator.canPop}",
            );

            return Scaffold(
              backgroundColor: backgroundColor,
              body: Padding(
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                child: widgets.dashView(false, [
                  ...items.map(
                    (item) => widgets.dashCardAction(
                      item,
                      context,
                      items.length + (navigator.canPop ? 1 : 0),
                    ),
                  ),

                  if (navigator.canPop)
                    widgets.dashCardAction(
                      DashAction(
                        label: "Back",
                        icons: [Icons.undo_rounded],
                        action: () {
                          debugPrint("Calling pop");
                          navigator.pop();
                        },
                      ),
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    showVolumeTip = prefs.getBool("show_volume_tip") ?? true;

    // loading = false;
    setState(() {});

    // Show popup after UI builds
    // if (showVolumeTip) {
    //   Future.delayed(Duration(milliseconds: 300), _showSettingsTip);
    // }
  }
}
