import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/commons/split_screen_observer.dart';
import 'package:moto_dash/service/assistant_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends SplitScreenState<HomeScreen> {
  Color backgroundColor = ConfigProvider.getBackgroundColor;
  Color fontColor = ConfigProvider.getFontColor;
  Color borderColor = ConfigProvider.getOptionBorderColor;

  bool showIcons = ConfigProvider.getShowIcons(Constants.kPathHome);
  bool showLabel = ConfigProvider.getShowLabel(Constants.kPathHome);
  bool loading = true;
  bool showVolumeTip = true;
  bool hasFavContacts = false;

  double fontSize = ConfigProvider.getFontSize;
  bool showSettingsButton = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    // Hide settings button after 10 seconds (launch-only)
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          showSettingsButton = false;
        });
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    showVolumeTip = prefs.getBool("show_volume_tip") ?? true;
    hasFavContacts =
        prefs.getStringList("fav_contact_names")?.toList().isNotEmpty ?? false;

    loading = false;
    setState(() {});

    // Show popup after UI builds
    if (showVolumeTip) {
      Future.delayed(Duration(milliseconds: 300), _showSettingsTip);
    }
  }

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();
    int itemCount = showSettingsButton ? 5 : 4;

    // Set Widget properties
    widgets.backgroundColor = backgroundColor;
    widgets.fontColor = fontColor;
    widgets.borderColor = borderColor;

    // Split Screen Settings
    if (isSplitScreen) {
      widgets.showLabel = false;
      widgets.showIcons = true;
    } else {
      widgets.showIcons = showIcons;
      widgets.showLabel = showLabel;
    }
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
        child: widgets.dashView(isSplitScreen, [
          // Phone
          widgets.dashCardRoute(
            'Phone',
            [Icons.phone_rounded],
            isSplitScreen
                ? (!hasFavContacts
                      ? Constants.kPathCallLog
                      : Constants.kPathCallNav)
                : (hasFavContacts
                      ? Constants.kPathCallFav
                      : Constants.kPathCallLog),
            context,
            itemCount,
          ),

          // Music Control
          widgets.dashCardRoute(
            'Music',
            [Icons.music_note_rounded],
            Constants.kPathMusic,
            context,
            itemCount,
          ),

          // Assistant Trigger
          widgets.dashCardFunc(
            'Assistant',
            [Icons.assistant_rounded],
            () => AssistantLauncher.launch(),
            context,
            itemCount,
          ),

          // Settings Button
          if (showSettingsButton)
            widgets.dashCardRoute(
              'Settings',
              [Icons.settings_rounded],
              Constants.kPathSettings,
              context,
              itemCount,
            ),

          // Volume Control
          widgets.dashCardRoute(
            'Volume',
            [Icons.volume_up_rounded],
            Constants.kPathVolume,
            context,
            itemCount,
          ),
        ]),
      ),
    );
  }

  void _showSettingsTip() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Tip"),
        content: const Text(
          "Settings menu button will be displayed on every app launch for 10 seconds. Relaunch the app to see it again.",
        ),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text("Never show again"),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool("show_volume_tip", false);
              showVolumeTip = false;

              if (!context.mounted) return;
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
