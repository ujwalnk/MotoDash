import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum AppIntent { next, select, back }

class MagnetIntentService {
  final _intentController = StreamController<AppIntent>.broadcast();
  Stream<AppIntent> get intents => _intentController.stream;

  StreamSubscription<MagnetometerEvent>? _sub;

  int _count = 0;
  DateTime _lastActiveTime = DateTime.now();

  Timer? _activeCheckTimer;

  bool _isNear = false;

  // ==========================
  // START / STOP
  // ==========================

  void start() {
    _sub = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 25),
    ).listen(_onData);
  }

  void stop() {
    _sub?.cancel();
    _activeCheckTimer?.cancel();
  }

  void dispose() {
    stop();
    _intentController.close();
  }

  // ==========================
  // SENSOR HANDLER
  // ==========================

  void _onData(MagnetometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    debugPrint("State: $magnitude");

    if (magnitude > 100) {
      if (!_isNear) {
        _isNear = true;
        debugPrint("Outer State: Near");
        _onEnterActive();
      }
    } else if (magnitude < 70) {
      _isNear = false;
      debugPrint("Outer State: Far");
    }
  }

  // ==========================
  // INNER LOGIC (UNCHANGED)
  // ==========================

  void _onEnterActive() {
    debugPrint("Inner State: Active");
    _count++;
    _lastActiveTime = DateTime.now();

    _activeCheckTimer?.cancel();

    _activeCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      final diff = DateTime.now().difference(_lastActiveTime);

      if (diff >= const Duration(seconds: 1)) {
        timer.cancel();
        _emitIntentFromCount(_count);
        _count = 0;
      }
    });
  }

  // ==========================
  // INTENT EMISSION
  // ==========================

  void _emitIntentFromCount(int count) {
    if (count == 1) {
      _intentController.add(AppIntent.next);
      // HapticFeedback.selectionClick();
      // SystemSound.play(SystemSoundType.alert);
    } else if (count == 2) {
      _intentController.add(AppIntent.select);
    } else if (count >= 3) {
      _intentController.add(AppIntent.back);
    }
  }
}
