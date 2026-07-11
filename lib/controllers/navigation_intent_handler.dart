// Author: Ujwal N K
// Created:
// Magnet navigation controller - handle the intent produced by the [magnet_intent_detector], and perform the navigation

import 'dart:async';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/navigation_graph.dart';
import 'package:moto_dash/screens/pages/page_map.dart';
import 'package:moto_dash/services/global_service.dart';

import 'navigation_intent_bus.dart';

enum NavigationIntent { previous, next, select, back, emergency }

class NavigationIntentHandler {
  NavigationIntentHandler._();

  static final NavigationIntentHandler instance = NavigationIntentHandler._();

  StreamSubscription<NavigationIntent>? _sub;
  int _selectedIndex = 0;

  // -------------------------
  // START / STOP
  // -------------------------

  void init() {
    if (!ConfigProvider.riderGesturesEnabled) return;
    magnetIntentService.init();
    _sub = NavigationIntentBus.stream.listen(_handleIntent);
  }

  void dispose() {
    if (!ConfigProvider.riderGesturesEnabled) return;
    magnetIntentService.dispose();
    _sub?.cancel();
    NavigationIntentBus.dispose();
  }

  // -------------------------
  // INTENT HANDLER
  // -------------------------

  Future<void> _handleIntent(NavigationIntent intent) async {
    final NavigationGraph navigator = NavigationGraph.instance;
    final builder = menuActions[navigator.page];

    if (builder == null) return;

    final List<DashAction> items = await builder();
    final int total = items.length + (navigator.canPop ? 1 : 0);

    // Rotate through the available menu
    if (_selectedIndex >= total) {
      _selectedIndex = 0;
    }

    switch (intent) {
      case NavigationIntent.next:
        // Skip reading the items that don't have any actions
        do {
          _selectedIndex = (_selectedIndex + 1) % total;
        } while (_selectedIndex < items.length && items[_selectedIndex].action == null);

        _speak(items, navigator);
        break;

      case NavigationIntent.select:
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

      case NavigationIntent.back:
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

      case NavigationIntent.previous:
        // TODO: Untested
        // Skip reading the items that don't have any actions
        do {
          _selectedIndex = (_selectedIndex - 1) % total;
        } while (_selectedIndex < items.length && items[_selectedIndex].action == null);

        _speak(items, navigator);
        break;

      case NavigationIntent.emergency:
        // TODO: Implement this, & test it
        _speak(items, navigator);
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
