// Author: Ujwal N K /w Claude
// Created: 2026.07.24
// Interprets raw button-press events from BleHidBridge into single/double/triple tap gestures
// for registered BLE buttons, and emits the configured NavigationIntent. Same tap-tracking logic
// as bt_intent_detector.dart - only the event source and per-button key (a hex code string
// instead of an int keyCode) differ.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/permission_check.dart';
import 'package:moto_dash/controllers/ble_hid_intent_detector/ble_hid_bridge.dart';
import 'package:moto_dash/controllers/ble_hid_intent_detector/ble_registered_key.dart';
import 'package:moto_dash/controllers/navigation_intent_bus.dart';
import 'package:moto_dash/controllers/navigation_intent_handler.dart' show NavigationIntent;
import 'package:moto_dash/services/notification_service.dart';

class BleIntentDetector extends ChangeNotifier {
  static StreamSubscription? _subscription;
  static StreamSubscription<BluetoothConnectionState>? _connStatusSub;
  static final Map<String, _TapTracker> _trackers = {};

  static bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (!await PermissionCheck.bluetooth) return;
    if (!ConfigProvider.riderGesturesBleEnabled) return;
    if (_initialized) return;

    _subscription = BleHidBridge.instance.events.listen(_handleEvent);
    _connStatusSub = BleHidBridge.instance.connectionState.listen(_handleConnectionChange);

    BleHidBridge.instance.reconnectSaved().then(
      (ok) => _handleConnectionChange(ok ? BluetoothConnectionState.connected : BluetoothConnectionState.disconnected),
    );

    _initialized = true;
    notifyListeners();
  }

  Future<void> terminate() async {
    if (!ConfigProvider.riderGesturesBleEnabled) return;
    if (!_initialized) return;
    await _subscription?.cancel();
    await _connStatusSub?.cancel();
    for (final tracker in _trackers.values) {
      tracker.dispose();
    }
    _trackers.clear();

    _initialized = false;
    notifyListeners();
  }

  static void _handleConnectionChange(BluetoothConnectionState state) {
    final name = ConfigProvider.riderGesturesBleDeviceName ?? "BLE remote";
    final status = state == BluetoothConnectionState.connected ? "Connected to $name" : "Not connected";
    NotificationService.updateConnectionStatus(status);
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
