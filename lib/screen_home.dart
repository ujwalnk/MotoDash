import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/commons/split_screen_observer.dart';
import 'package:moto_dash/service/assistant_launcher.dart';
import 'package:moto_dash/service/global_services.dart';
import 'package:moto_dash/service/magent_intent_detector.dart';
import 'package:moto_dash/main.dart'; // for routeObserver

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends SplitScreenState<HomeScreen> with RouteAware {
  bool showIcons = ConfigProvider.getShowIcons(Constants.kPathHome);
  bool showLabel = ConfigProvider.getShowLabel(Constants.kPathHome);
  bool loading = true;
  bool showVolumeTip = true;
  bool hasFavContacts = false;
  bool showSettingsButton = true;

  int selectedIndex = ConfigProvider.getEnableMagnetGestures ? 0 : -1;

  StreamSubscription<AppIntent>? _intentSub;
  late List<VoidCallback> _actions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _unsubscribe();
    super.dispose();
  }

  // -----------------------------
  // RouteAware lifecycle
  // -----------------------------

  @override
  void didPush() => _subscribe();

  @override
  void didPopNext() {
    // Reset the index
    if (selectedIndex != -1) {
      setState(() => selectedIndex = 0);
    }
    _subscribe();
  }

  @override
  void didPushNext() => _unsubscribe();

  void _subscribe() {
    _intentSub = magnetService.intents.listen(_handleIntent);
  }

  void _unsubscribe() {
    _intentSub?.cancel();
    _intentSub = null;
  }

  // -----------------------------

  @override
  void initState() {
    // _subscribe();
    super.initState();
    _loadSettings();

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        // setState(() => showSettingsButton = false);
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    showVolumeTip = prefs.getBool("show_volume_tip") ?? true;
    hasFavContacts =
        prefs.getStringList("fav_contact_names")?.isNotEmpty ?? false;

    loading = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();

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

    _actions = [
      () {
        Navigator.pushNamed(
          context,
          isSplitScreen
              ? (!hasFavContacts
                    ? Constants.kPathCallLog
                    : Constants.kPathCallNav)
              : (hasFavContacts
                    ? Constants.kPathCallFav
                    : Constants.kPathCallLog),
        );
      },
      () => Navigator.pushNamed(context, Constants.kPathMusic),
      () => AssistantLauncher.launch(),
      if (showSettingsButton)
        () => Navigator.pushNamed(context, Constants.kPathSettings),
      () => Navigator.pushNamed(context, Constants.kPathVolume),
    ];

    return Scaffold(
      backgroundColor: ConfigProvider.getBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: widgets.dashView(isSplitScreen, [
          widgets.dashCardFunc(
            'Phone',
            [Icons.phone_rounded],
            _actions[0],
            context,
            _actions.length,
            isSelected: selectedIndex == 0,
          ),
          widgets.dashCardFunc(
            'Music',
            [Icons.music_note_rounded],
            _actions[1],
            context,
            _actions.length,
            isSelected: selectedIndex == 1,
          ),
          widgets.dashCardFunc(
            'Assistant',
            [Icons.assistant_rounded],
            _actions[2],
            context,
            _actions.length,
            isSelected: selectedIndex == 2,
          ),
          if (showSettingsButton)
            widgets.dashCardFunc(
              'Settings',
              [Icons.settings_rounded],
              _actions[3],
              context,
              _actions.length,
              isSelected: selectedIndex == 3,
            ),
          widgets.dashCardFunc(
            'Volume',
            [Icons.volume_up_rounded],
            showSettingsButton ? _actions[4] : _actions[3],
            context,
            _actions.length,
            isSelected: selectedIndex == 3,
          ),
        ]),
      ),
    );
  }

  void _handleIntent(AppIntent intent) {
    switch (intent) {
      case AppIntent.next:
        setState(() {
          selectedIndex = (selectedIndex + 1) % _actions.length;
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
}
