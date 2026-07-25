// Author: Ujwal N K /w Claude
// Created: 2026.07.24
// Interprets raw button-press events from BleHidBridge into single/double/triple tap gestures
// for registered BLE buttons, and emits the configured NavigationIntent. Same tap-tracking logic
// as bt_intent_detector.dart - only the event source and per-button key (a hex code string
// instead of an int keyCode) differ.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/controllers/ble_hid_intent_detector/ble_hid_bridge.dart';
import 'package:moto_dash/controllers/ble_hid_intent_detector/ble_registered_key.dart';
import 'package:moto_dash/controllers/navigation_intent_bus.dart';
import 'package:moto_dash/controllers/navigation_intent_handler.dart' show NavigationIntent;

class BleIntentDetector {
  static StreamSubscription? _subscription;
  static final Map<String, _TapTracker> _trackers = {};

  static void init() {
    if (!ConfigProvider.riderGesturesBleEnabled) return;
    _subscription = BleHidBridge.instance.events.listen(_handleEvent);
    BleHidBridge.instance.reconnectSaved();
  }

  static void dispose() {
    if (!ConfigProvider.riderGesturesBleEnabled) return;
    _subscription?.cancel();
    for (final tracker in _trackers.values) {
      tracker.dispose();
    }
    _trackers.clear();
  }

  static void _handleEvent(Map<String, dynamic> event) {
    final String? code = event['code'] as String?;
    if (code == null) return;

    final tracker = _trackers.putIfAbsent(code, () => _TapTracker(code));
    tracker.registerTap();
  }

  static BleRegisteredKey? _findByCode(String code) {
    for (final key in ConfigProvider.riderGesturesBleKeys) {
      if (key.code == code) return key;
    }
    return null;
  }
}

class _TapTracker {
  _TapTracker(this.code);

  final String code;
  int _taps = 0;
  Timer? _timer;

  void registerTap() {
    _taps++;
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: ConfigProvider.riderGesturesBleTapDelay), _resolveGesture);
  }

  void _resolveGesture() {
    final int taps = _taps;
    _taps = 0;

    final BleRegisteredKey? registeredKey = BleIntentDetector._findByCode(code);
    if (registeredKey == null) return;

    final NavigationIntent? intent = switch (taps) {
      1 => registeredKey.singleTap,
      2 => registeredKey.doubleTap,
      3 => registeredKey.tripleTap,
      _ => null,
    };

    if (intent != null) {
      debugPrint("BleIntentDetector: sending intent $intent");
      NavigationIntentBus.emit(intent);
    }
  }

  void dispose() => _timer?.cancel();
}
