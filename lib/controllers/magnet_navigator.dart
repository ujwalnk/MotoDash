// Author: Ujwal N K
// Created:
// Magnet navigation controller - handle the intent produced by the [magnet_intent_detector], and perform the navigation

import 'dart:async';

import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/controllers/magnet_intent_detector.dart';
import 'package:moto_dash/navigation_graph.dart';
import 'package:moto_dash/screens/pages/page_map.dart';
import 'package:moto_dash/services/global_service.dart';

class MagnetNavigator {
  MagnetNavigator._();

  static final MagnetNavigator instance = MagnetNavigator._();

  StreamSubscription<AppIntent>? _sub;

  int _selectedIndex = 0;

  // -------------------------
  // START / STOP
  // -------------------------

  void start() {
    _sub = magnetService.intents.listen(_handleIntent);
  }

  void stop() {
    _sub?.cancel();
  }

  // -------------------------
  // INTENT HANDLER
  // -------------------------

  Future<void> _handleIntent(AppIntent intent) async {
    final navigator = NavigationGraph.instance;
    final builder = menuActions[navigator.page];

    if (builder == null) return;

    final List<DashAction> items = await builder();
    final int total = items.length + (navigator.canPop ? 1 : 0);

    // Safety
    if (_selectedIndex >= total) {
      _selectedIndex = 0;
    }

    switch (intent) {
      case AppIntent.next:
        // Skip reading the items that don't have any actions
        do {
          _selectedIndex = (_selectedIndex + 1) % total;
        } while (_selectedIndex < items.length && items[_selectedIndex].action == null);

        _speak(items, navigator);
        break;

      case AppIntent.select:
        final oldPage = navigator.page;

        _performAction(items, navigator);

        final newPage = navigator.page;

        if (oldPage != newPage) {
          // Reset the selected index on page change
          _selectedIndex = 0;

          final newBuilder = menuActions[newPage];
          if (newBuilder != null) {
            final newItems = await newBuilder();
            _speak(newItems, navigator);
          }
        }
        break;

      case AppIntent.back:
        navigator.pop();

        // Reset index
        _selectedIndex = 0;

        // Speak first item of new page
        final newBuilder = menuActions[navigator.page];
        if (newBuilder != null) {
          final newItems = await newBuilder();
          _speak(newItems, navigator);
        }
        break;
    }
  }

  // -------------------------
  // ACTION EXECUTION
  // -------------------------

  void _performAction(List<DashAction> items, NavigationGraph navigator) {
    if (_selectedIndex < items.length) {
      items[_selectedIndex].action?.call();
    } else {
      navigator.pop();
    }
  }

  // -------------------------
  // SPEECH
  // -------------------------

  void _speak(List<DashAction> items, NavigationGraph navigator) {
    if (_selectedIndex < items.length) {
      ttsService.speak(items[_selectedIndex].label);
    } else {
      ttsService.speak("Back");
    }
  }
}
