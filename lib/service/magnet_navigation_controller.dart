// Author: Ujwal N K
// Created: 2026, Mar 22

import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:moto_dash/navigation_graph.dart';
import 'package:moto_dash/menu_actions.dart';
import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/service/global_services.dart';
import 'package:moto_dash/service/magent_intent_detector.dart';

class MagnetNavigationController {
  MagnetNavigationController._();

  static final MagnetNavigationController instance =
      MagnetNavigationController._();

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

    if (_selectedIndex >= total) _selectedIndex = 0;

    switch (intent) {
      case AppIntent.next:
        _selectedIndex = (_selectedIndex + 1) % total;
        _speak(items, navigator);
        break;

      case AppIntent.select:
        final oldPage = navigator.page;

        await _performAction(items, navigator);

        // Only check for page change if the action was local (not proxied).
        // Proxied actions foreground the app and are handled by the main
        // isolate — navigation state does not change in this isolate.
        final newPage = navigator.page;

        if (oldPage != newPage) {
          _selectedIndex = 0;
          final newBuilder = menuActions[newPage];
          if (newBuilder != null) {
            final newItems = await newBuilder();
            _speak(newItems, navigator);
          }
        } else {
          _speak(items, navigator);
        }
        break;

      case AppIntent.back:
        navigator.pop();
        _selectedIndex = 0;

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

  Future<void> _performAction(
    List<DashAction> items,
    NavigationGraph navigator,
  ) async {
    // Selected index is past the item list — treat as Back
    if (_selectedIndex >= items.length) {
      navigator.pop();
      return;
    }

    final action = items[_selectedIndex];

    if (action.requiresActivity) {
      // This action needs an Android Activity (dialer, assistant, etc.).
      // Tell the main isolate the page and index, then bring the app to
      // foreground so the Activity is ready to receive the platform channel call.
      FlutterForegroundTask.sendDataToMain({
        'action': 'execute_action',
        'page': navigator.page.name,
        'index': _selectedIndex,
      });
      FlutterForegroundTask.launchApp();
    } else {
      // Volume, navigation, and other pure-Dart/system-service actions
      // execute directly — no Activity needed
      action.action();
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