// Author: Ujwal N K
// Created: 2026, Mar 22
// Description: Root screen for MotoDash

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart' show ConfigProvider;
import 'package:moto_dash/commons/dash_action.dart' show DashAction;
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/menu_actions.dart' show menuActions;
import 'package:moto_dash/navigation_graph.dart' show NavigationGraph;

import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final navigator = NavigationGraph.instance;
    final widgets = DashWidgets();

    // Set Widget properties
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
          return const Center(child: CircularProgressIndicator());
        }

        // Safer to store the snapshot data, than reuse
        final items = snapshot.data as List<DashAction>;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
            // TODO: later add split screen support
            child: widgets.dashView(false, [
              ...items
                  .map(
                    (item) =>
                        widgets.dashCardAction(item, context, items.length),
                  )
                  .toList(),
              if (navigator.canPop)
                // If popable screen, add back Button at the end
                widgets.dashCardAction(
                  DashAction(
                    label: "Back",
                    icons: [Icons.undo_rounded],
                    action: () => NavigationGraph.instance.pop(),
                  ),
                  context,

                  // Count Correction for back button
                  navigator.canPop ? items.length + 1 : items.length,
                ),
            ]),
          ),
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
