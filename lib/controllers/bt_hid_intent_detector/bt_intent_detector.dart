// Author: Ujwal N K
// Created: 2026.07.12
// Interprets raw Android key events into single/double/triple tap gestures for registered
// Bluetooth HID keys, and emits the user-configured NavigationIntent for each completed gesture.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moto_dash/bridges/input_event_bridge.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/controllers/bt_hid_intent_detector/hid_key_registry.dart';
import 'package:moto_dash/controllers/navigation_intent_bus.dart';
import 'package:moto_dash/controllers/navigation_intent_handler.dart' show NavigationIntent;

/// Android's `KeyEvent.ACTION_DOWN`. Only key-down events count towards a tap; ACTION_UP is ignored.
const int _kActionDown = 0;

class BtIntentDetector {
  static late final StreamSubscription _subscription;

  /// One tracker per physical key code, so taps on different buttons are counted independently.
  static final Map<int, _TapTracker> _trackers = {};

  static void init() {
    if (!ConfigProvider.riderGesturesBtEnabled) return;
    _subscription = InputEventBridge.events.listen(_handleEvent);
  }

  static void dispose() {
    if (!ConfigProvider.riderGesturesBtEnabled) return;
    _subscription.cancel();
    for (final tracker in _trackers.values) {
      tracker.dispose();
    }
    _trackers.clear();
  }

  static void _handleEvent(Map<dynamic, dynamic> event) {
    final int? action = event['action'] as int?;
    if (action != _kActionDown) return;

    final int keyCode = event['keyCode'] as int;
    final tracker = _trackers.putIfAbsent(keyCode, () => _TapTracker(keyCode));
    tracker.registerTap();
  }

  static HidRegisteredKey? _findByKeyCode(int keyCode) {
    for (final key in ConfigProvider.riderGesturesHidKeys) {
      if (key.keyCode == keyCode) return key;
    }
    return null;
  }
}

/// Counts consecutive taps for a single [keyCode] and, once no further taps arrive within the
/// configured multi-tap window, resolves them into a single/double/triple tap gesture and emits
/// the NavigationIntent configured for that key - if any.
class _TapTracker {
  _TapTracker(this.keyCode);

  final int keyCode;

  int _taps = 0;
  Timer? _timer;

  void registerTap() {
    _taps++;
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: ConfigProvider.riderGesturesBtTapDelay), _resolveGesture);
  }

  void _resolveGesture() {
    final int taps = _taps;
    _taps = 0;

    final HidRegisteredKey? registeredKey = BtIntentDetector._findByKeyCode(keyCode);
    if (registeredKey == null) return;

    debugPrint("Got intent");

    final NavigationIntent? intent = switch (taps) {
      1 => registeredKey.singleTap,
      2 => registeredKey.doubleTap,
      3 => registeredKey.tripleTap,
      _ => null,
    };

    if (intent != null) {
      debugPrint("Sending intent: $intent");
      NavigationIntentBus.emit(intent);
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
