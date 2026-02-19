import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moto_dash/service/magent_intent_detector.dart';
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
  bool hasFavContacts = false;
  bool showVolumeTip = true;

  bool loading = true;

  bool showSettingsButton = true;

  int selectedIndex = 0;

  late MagnetIntentService magnetService;
  late StreamSubscription<AppIntent> _intentSub;

  late List<VoidCallback> _actions;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    magnetService = MagnetIntentService();
    magnetService.start();

    _intentSub = magnetService.intents.listen(handleIntent);

    // Hide settings button after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          showSettingsButton = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _intentSub.cancel();
    magnetService.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    showVolumeTip = prefs.getBool("show_volume_tip") ?? true;
    hasFavContacts =
        prefs.getStringList("fav_contact_names")?.isNotEmpty ?? false;

    loading = false;

    if (mounted) setState(() {});

    if (showVolumeTip) {
      Future.delayed(const Duration(milliseconds: 300), _showSettingsTip);
    }
  }

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();

    widgets.backgroundColor = backgroundColor;
    widgets.fontColor = fontColor;
    widgets.borderColor = borderColor;

    widgets.showLabel = isSplitScreen ? false : showIcons;
    widgets.showIcons = isSplitScreen ? true : showLabel;

    final int itemCount = showSettingsButton ? 5 : 4;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ==============================
    // Define Actions (Single Source)
    // ==============================

    _actions = [
      () => Navigator.pushNamed(context, resolvePhonePath()),
      () => Navigator.pushNamed(context, Constants.kPathMusic),
      () => AssistantLauncher.launch(),
      () => Navigator.pushNamed(context, Constants.kPathVolume),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
        child: widgets.dashView(isSplitScreen, [
          widgets.dashCardFunc(
            'Phone',
            [Icons.phone_rounded],
            _actions[0],
            context,
            itemCount,
            isSelected: selectedIndex == 0,
          ),
          widgets.dashCardFunc(
            'Music',
            [Icons.music_note_rounded],
            _actions[1],
            context,
            itemCount,
            isSelected: selectedIndex == 1,
          ),
          widgets.dashCardFunc(
            'Assistant',
            [Icons.assistant_rounded],
            _actions[2],
            context,
            itemCount,
            isSelected: selectedIndex == 2,
          ),
          if (showSettingsButton)
            widgets.dashCardFunc(
              'Settings',
              [Icons.settings_rounded],
              () => Navigator.pushNamed(context, Constants.kPathSettings),
              context,
              itemCount,
              isSelected: selectedIndex == 3,
            ),
          widgets.dashCardFunc(
            'Volume',
            [Icons.volume_up_rounded],
            _actions[3],
            context,
            itemCount,
            isSelected: selectedIndex == 3,
          ),
        ]),
      ),
    );
  }

  String resolvePhonePath() {
    return isSplitScreen
        ? (!hasFavContacts ? Constants.kPathCallLog : Constants.kPathCallNav)
        : (hasFavContacts ? Constants.kPathCallFav : Constants.kPathCallLog);
  }

  // ==============================
  // Magnet Intent Handler
  // ==============================

  void handleIntent(AppIntent intent) {
    final itemCount = _actions.length;

    switch (intent) {
      case AppIntent.next:
        setState(() {
          selectedIndex = (selectedIndex + 1) % itemCount;
        });
        break;

      case AppIntent.select:
        _actions[selectedIndex]();
        break;

      case AppIntent.back:
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        break;
    }
  }

  // ==============================
  // Settings Tip Dialog
  // ==============================

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
