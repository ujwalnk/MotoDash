// Author: Ujwal N K
// Date: 2026-02-24
// Description: Home screen for MotoDash

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/commons/split_screen_observer.dart';
import 'package:moto_dash/commons/list_builder.dart';

import 'package:moto_dash/service/assistant_launcher.dart';
import 'package:moto_dash/service/global_services.dart';
import 'package:moto_dash/service/magent_intent_detector.dart';

import 'package:moto_dash/main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends SplitScreenState<HomeScreen> with RouteAware {
  bool showIcons = ConfigProvider.getShowIcons(Constants.kPathHome);
  bool showLabel = ConfigProvider.getShowLabel(Constants.kPathHome);

  bool loading = true;
  bool hasFavContacts = false;
  bool showSettingsButton = true;

  int selectedIndex = ConfigProvider.getEnableMagnetGestures ? 0 : -1;

  StreamSubscription<AppIntent>? _intentSub;

  List<DashAction> _items = [];

  bool _didAutoSpeak = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _intentSub?.cancel();
    super.dispose();
  }

  @override
  void didPush() => _subscribe();

  @override
  void didPushNext() => _unsubscribe();

  @override
  void didPopNext() {
    _subscribe();
    _didAutoSpeak = false;
    _maybeSpeakFirst();
  }

  void _subscribe() {
    _intentSub = magnetService.intents.listen(_handleIntent);
  }

  void _unsubscribe() {
    _intentSub?.cancel();
    _intentSub = null;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();

    hideSettings();
  }

  void hideSettings() async {
    await Future.delayed(const Duration(seconds: 10));
    if (mounted) {
      setState(() {
        showSettingsButton = false;
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    hasFavContacts =
        prefs.getStringList("fav_contact_names")?.isNotEmpty ?? false;

    loading = false;
    if (mounted) setState(() {});
  }

  void _handleIntent(AppIntent intent) {
    if (selectedIndex == -1 || _items.isEmpty) return;

    switch (intent) {
      case AppIntent.next:
        setState(() {
          selectedIndex = (selectedIndex + 1) % _items.length;
        });
        ttsService.speak(_items[selectedIndex].label);
        break;

      case AppIntent.select:
        _items[selectedIndex].action();
        break;

      case AppIntent.back:
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        break;
    }
  }

  void _maybeSpeakFirst() {
    if (lastNavigationWasMagnet &&
        !_didAutoSpeak &&
        selectedIndex != -1 &&
        _items.isNotEmpty) {
      _didAutoSpeak = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => selectedIndex = 0);
        ttsService.speak(_items[0].label);
        lastNavigationWasMagnet = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final widgets = DashWidgets();

    widgets.showIcons = isSplitScreen ? true : showIcons;
    widgets.showLabel = isSplitScreen ? false : showLabel;

    _items = [
      DashAction(
        label: 'Phone',
        icons: [Icons.phone_rounded],
        action: () {
          if (lastNavigationWasMagnet) {
            Navigator.pushNamed(context, Constants.kPathCallNav);
          } else {
            Navigator.pushNamed(context, Constants.kPathCallLog);
          }
        },
      ),
      DashAction(
        label: 'Music',
        icons: [Icons.music_note_rounded],
        action: () => Navigator.pushNamed(context, Constants.kPathMusic),
      ),
      DashAction(
        label: 'Assistant',
        icons: [Icons.assistant_rounded],
        action: () => AssistantLauncher.launch(),
      ),
      if (showSettingsButton)
        DashAction(
          label: 'Settings',
          icons: [Icons.settings_rounded],
          action: () => Navigator.pushNamed(context, Constants.kPathSettings),
        ),
      DashAction(
        label: 'Volume',
        icons: [Icons.volume_up_rounded],
        action: () => Navigator.pushNamed(context, Constants.kPathVolume),
      ),
    ];

    _maybeSpeakFirst();

    return Scaffold(
      backgroundColor: ConfigProvider.getBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: widgets.dashView(
          isSplitScreen,
          List.generate(_items.length, (index) {
            return widgets.dashCardAction(
              _items[index],
              context,
              _items.length,
              isSelected: selectedIndex == index,
            );
          }),
        ),
      ),
    );
  }
}
