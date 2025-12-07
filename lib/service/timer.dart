import 'dart:async';
import 'package:flutter/material.dart';

class IdleTimer with WidgetsBindingObserver {
  static final IdleTimer instance = IdleTimer._internal();
  IdleTimer._internal();

  // Navigator key injected from main.dart
  GlobalKey<NavigatorState>? navigatorKey;

  Timer? _timer;
  bool enabled = false; // keepScreenBlank
  Duration timeout = const Duration(seconds: 2);

  /// Setup (called once from MaterialApp builder)
  void initialize(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    WidgetsBinding.instance.addObserver(this);
  }

  /// Enable or disable the idle timer
  void setEnabled(bool value) {
    enabled = value;

    if (!enabled) {
      _timer?.cancel();
    } else {
      resetTimer();
    }
  }

  /// Reset timer when user touches screen or app resumes
  void registerActivity() {
    resetTimer();
  }

  /// Start the inactivity countdown
  void resetTimer() {
    if (!enabled) return;

    _timer?.cancel();
    _timer = Timer(timeout, _triggerSaver);
  }

  /// Navigate to /saver using the global navigator key
  void _triggerSaver() {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) return;

    // Prevent multiple pushes when user taps while navigating
    if (navigator.canPop()) {
      navigator.pushNamed("/saver");
    } else {
      navigator.pushNamed("/saver");
    }
  }

  /// Reset timer when app resumes from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resetTimer();
    }
  }
}
