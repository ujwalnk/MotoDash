import 'dart:async';
import 'package:flutter/material.dart';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/commons/split_screen_observer.dart';

import 'package:moto_dash/service/global_services.dart';
import 'package:moto_dash/service/magent_intent_detector.dart';
import 'package:moto_dash/main.dart';

class CallNavScreen extends StatefulWidget {
  const CallNavScreen({super.key});

  @override
  State<CallNavScreen> createState() => _CallNavScreenState();
}

class _CallNavScreenState extends SplitScreenState<CallNavScreen>
    with RouteAware {
  final bool showIcons = ConfigProvider.getShowIcons(Constants.kPathCallNav);
  final bool showLabel = ConfigProvider.getShowLabel(Constants.kPathCallNav);

  double fontSize = ConfigProvider.getFontSize;

  List<String> names = [];
  List<String> numbers = [];

  bool loading = true;

  int selectedIndex = ConfigProvider.getEnableMagnetGestures ? 0 : -1;

  StreamSubscription<AppIntent>? _intentSub;

  List<String> _labels = [];
  List<VoidCallback> _actions = [];

  bool _didAutoSpeak = false;

  // ------------------------------------------------
  // RouteAware
  // ------------------------------------------------

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

  @override
  void didPush() {
    _subscribe();
    _didAutoSpeak = false;
    _maybeSpeakFirst();
  }

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

  // ------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    names = prefs.getStringList("fav_contact_names") ?? [];
    numbers = prefs.getStringList("fav_contact_numbers") ?? [];

    loading = false;
    if (mounted) setState(() {});
  }

  // ------------------------------------------------

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();

    widgets.showIcons = ConfigProvider.getShowIcons(Constants.kPathCallLog);
    widgets.showLabel = ConfigProvider.getShowLabel(Constants.kPathCallLog);

    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _labels = ["Favourites", "Call Log", "Return"];

    _actions = [
      () => Navigator.pushNamed(context, Constants.kPathCallFav),
      () => Navigator.pushNamed(context, Constants.kPathCallLog),
      () => Navigator.pop(context),
    ];

    final int itemCount = _labels.length;

    if (selectedIndex >= itemCount) {
      selectedIndex = itemCount - 1;
    }

    _maybeSpeakFirst();

    return Scaffold(
      backgroundColor: ConfigProvider.getBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
        child: widgets.dashView(isSplitScreen, [
          for (int i = 0; i < itemCount; i++)
            widgets.dashCardFunc(
              _labels[i],
              i == 0
                  ? [Icons.star_rounded]
                  : i == 1
                  ? [Icons.history_rounded]
                  : [Icons.undo_rounded],
              _actions[i],
              context,
              itemCount,
              isSelected: selectedIndex == i,
            ),
        ]),
      ),
    );
  }

  // ------------------------------------------------
  // Magnet Handler
  // ------------------------------------------------

  void _handleIntent(AppIntent intent) {
    if (_actions.isEmpty || selectedIndex == -1) return;

    switch (intent) {
      case AppIntent.next:
        setState(() {
          selectedIndex = (selectedIndex + 1) % _actions.length;
        });

        ttsService.speak(_labels[selectedIndex]);
        break;

      case AppIntent.select:
        _actions[selectedIndex]();
        break;

      case AppIntent.back:
        Navigator.pop(context);
        break;
    }
  }

  // ------------------------------------------------
  // Auto speak only if magnet navigation
  // ------------------------------------------------

  void _maybeSpeakFirst() {
    if (lastNavigationWasMagnet &&
        !_didAutoSpeak &&
        selectedIndex != -1 &&
        _labels.isNotEmpty) {
      _didAutoSpeak = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() => selectedIndex = 0);
        ttsService.speak(_labels[0]);

        lastNavigationWasMagnet = false;
      });
    }
  }
}
