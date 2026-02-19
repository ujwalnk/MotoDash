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
  final Color backgroundColor = ConfigProvider.getBackgroundColor;
  final Color fontColor = ConfigProvider.getFontColor;
  final Color borderColor = ConfigProvider.getBorderColor;

  final bool showIcons = ConfigProvider.getShowIcons(Constants.kPathCallFav);
  final bool showLabel = ConfigProvider.getShowLabel(Constants.kPathCallFav);

  List<String> names = [];
  List<String> numbers = [];

  bool loading = true;
  int selectedIndex = 0;

  StreamSubscription<AppIntent>? _intentSub;
  late List<VoidCallback> _actions;

  // -----------------------------
  // RouteAware lifecycle
  // -----------------------------

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
  void didPopNext() => _subscribe();

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

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();

    widgets.backgroundColor = backgroundColor;
    widgets.fontColor = fontColor;
    widgets.borderColor = borderColor;

    if (isSplitScreen) {
      widgets.showLabel = true;
      widgets.showIcons = false;
    } else {
      widgets.showIcons = showIcons;
      widgets.showLabel = showLabel;
    }

    if (loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // -----------------------------
    // Build Actions Dynamically
    // -----------------------------

    _actions = [];

    // Favorite contacts
    final int visibleContacts = isSplitScreen
        ? (names.length.clamp(0, 4))
        : names.length;

    for (int i = 0; i < visibleContacts; i++) {
      final int index = i;
      _actions.add(() async {
        await FlutterPhoneDirectCaller.callNumber(numbers[index]);
      });
    }

    // Call Log button (only when NOT split screen)
    if (!isSplitScreen) {
      _actions.add(() {
        Navigator.pushNamed(context, Constants.kPathCallLog);
      });
    }

    // Return button
    _actions.add(() {
      Navigator.pop(context);
    });

    final int itemCount = _actions.length;

    // Safety: clamp selectedIndex if list shrinks
    if (selectedIndex >= itemCount) {
      selectedIndex = itemCount - 1;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: widgets.dashView(isSplitScreen, [
          // -------------------------------
          // FAVORITE CONTACTS
          // -------------------------------
          for (int i = 0; i < visibleContacts; i++)
            widgets.dashCardFunc(
              isSplitScreen
                  ? names[i].substring(
                      0,
                      names[i].length > 10 ? 10 : names[i].length,
                    )
                  : names[i],
              [Icons.person_rounded],
              _actions[i],
              context,
              itemCount,
              isSelected: selectedIndex == i,
            ),

          // -------------------------------
          // CALL LOG (if applicable)
          // -------------------------------
          if (!isSplitScreen)
            widgets.dashCardFunc(
              'Call Log',
              [Icons.history_rounded],
              _actions[visibleContacts],
              context,
              itemCount,
              isSelected: selectedIndex == visibleContacts,
            ),

          // -------------------------------
          // RETURN BUTTON
          // -------------------------------
          widgets.dashCardFunc(
            'Return',
            [Icons.undo_rounded],
            _actions[itemCount - 1],
            context,
            itemCount,
            isSelected: selectedIndex == itemCount - 1,
            overrideShowIcons: true,
            overrideShowLabel: false,
          ),
        ]),
      ),
    );
  }

  // -----------------------------
  // Magnet Intent Handler
  // -----------------------------

  void _handleIntent(AppIntent intent) {
    if (_actions.isEmpty) return;

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
        Navigator.pop(context);
        break;
    }
  }
}
