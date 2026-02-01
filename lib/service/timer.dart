import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moto_dash/commons/commons.dart';

class IdleTimer with WidgetsBindingObserver {
  static final IdleTimer instance = IdleTimer._internal();
  IdleTimer._internal();

  GlobalKey<NavigatorState>? navigatorKey;

  Timer? _timer;
  bool enabled = false;
  Duration timeout = const Duration(minutes: 2);

  void initialize(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> loadTimeoutFromPrefs() async {
    timeout = await loadBlankTimeDuration();
  }

  /// Enable or disable idle detection
  Future<void> setEnabled(bool value) async {
    enabled = value;

    _timer?.cancel();

    if (!enabled) return;

    await loadTimeoutFromPrefs();
    resetTimer();
  }

  void registerActivity() {
    if (!enabled) return;
    resetTimer();
  }

  void resetTimer() {
    if (!enabled) return;

    _timer?.cancel();
    _timer = Timer(timeout, _triggerSaver);
  }

  void _triggerSaver() {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) return;

    // Prevent stacking saver routes
    if (navigator.canPop()) return;

    navigator.pushNamed("/saver");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && enabled) {
      resetTimer();
    }
  }
}
