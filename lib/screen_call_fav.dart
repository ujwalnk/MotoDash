import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/commons/split_screen_observer.dart';
import 'package:moto_dash/service/global_services.dart';
import 'package:moto_dash/service/magent_intent_detector.dart';
import 'package:moto_dash/main.dart';

class FavContactsScreen extends StatefulWidget {
  const FavContactsScreen({super.key});

  @override
  State<FavContactsScreen> createState() => _FavContactsScreenState();
}

class _FavContactsScreenState extends SplitScreenState<FavContactsScreen>
    with RouteAware {
  final bool showIcons = ConfigProvider.getShowIcons(Constants.kPathCallFav);
  final bool showLabel = ConfigProvider.getShowLabel(Constants.kPathCallFav);

  List<String> names = [];
  List<String> numbers = [];

  bool loading = true;
  int selectedIndex = ConfigProvider.getEnableMagnetGestures ? 0 : -1;

  StreamSubscription<AppIntent>? _intentSub;

  List<VoidCallback> _actions = [];
  List<String> _labels = [];

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

  // ------------------------------------------------
  // INIT
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
  // BUILD
  // ------------------------------------------------

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();

    if (isSplitScreen) {
      widgets.showLabel = true;
      widgets.showIcons = false;
    } else {
      widgets.showIcons = showIcons;
      widgets.showLabel = showLabel;
    }

    if (loading) {
      return Scaffold(
        backgroundColor: ConfigProvider.getBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _actions = [];
    _labels = [];

    final int visibleContacts = isSplitScreen
        ? names.length.clamp(0, 4)
        : names.length;

    // -----------------------------
    // Favorite Contacts
    // -----------------------------

    for (int i = 0; i < visibleContacts; i++) {
      final int index = i;

      final label = isSplitScreen
          ? names[i].substring(0, names[i].length > 10 ? 10 : names[i].length)
          : names[i];

      _labels.add(label);

      _actions.add(() async {
        await FlutterPhoneDirectCaller.callNumber(numbers[index]);
      });
    }

    // -----------------------------
    // Return
    // -----------------------------

    _labels.add("Return");
    _actions.add(() {
      Navigator.pop(context);
    });

    final int itemCount = _actions.length;

    if (selectedIndex >= itemCount) {
      selectedIndex = itemCount - 1;
    }

    _maybeSpeakFirst();

    return Scaffold(
      backgroundColor: ConfigProvider.getBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: widgets.dashView(
          isSplitScreen,
          List.generate(itemCount, (i) {
            return widgets.dashCardFunc(
              _labels[i],
              i < visibleContacts
                  ? [Icons.person_rounded]
                  : i == itemCount - 1
                  ? [Icons.undo_rounded]
                  : [Icons.history_rounded],
              _actions[i],
              context,
              itemCount,
              isSelected: selectedIndex == i,
              overrideShowIcons: i == itemCount - 1,
              overrideShowLabel: i == itemCount - 1 ? false : null,
            );
          }),
        ),
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
  // Auto speak if magnet navigation
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
