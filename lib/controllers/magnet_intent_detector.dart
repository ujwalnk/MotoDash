// Author: Ujwal N K
// Created:
// Magnet intent detector, to detect the action to be taken based on the user rider gestures

import 'dart:async';
import 'dart:math';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/controllers/navigation_intent_bus.dart';
import 'package:moto_dash/services/beep_service.dart';
import 'package:moto_dash/services/global_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:statemachine/statemachine.dart' as machine;

import 'navigation_intent_handler.dart' show NavigationIntent;

class MagnetIntentService {
  StreamSubscription<MagnetometerEvent>? _sub;

  // ==========================
  // TIMEOUT DURATION
  // ==========================

  static final Duration _timeoutDuration = Duration(milliseconds: ConfigProvider.riderGesturesMagnetTapDelay.toInt());
  static bool humanContextTimeout = true; // Hotfix: Speak the current selected item after timeout

  // ==========================
  // SAMPLING CONTROL
  // ==========================

  static const Duration _slowSampling = Duration(milliseconds: 100);
  static const Duration _fastSampling = Duration(milliseconds: 33);

  Duration? _currentSampling;

  void _startSampling(Duration period) {
    if (_currentSampling == period && _sub != null) return;

    _sub?.cancel();
    _currentSampling = period;

    _sub = magnetometerEventStream(samplingPeriod: period).listen(_onData);
  }

  // ==========================
  // BASELINE
  // ==========================

  double _baseline = 0;
  bool _baselineInitialized = false;

  static final double _enterDelta = ConfigProvider.riderGesturesMagnetStrength;
  static final double _exitDelta = ConfigProvider.riderGesturesMagnetStrength * 0.4;

  // ==========================
  // TAP GROUPING
  // ==========================

  int _count = 0;
  DateTime _lastActiveTime = DateTime.now();
  Timer? _activeTimer;

  // ==========================
  // FSM
  // ==========================

  final machine.Machine<String> _outerM = machine.Machine<String>();
  final machine.Machine<String> _innerM = machine.Machine<String>();

  late final machine.State _stateFar;
  late final machine.State _stateNear;
  late final machine.State _stateBias;

  late final machine.State _stateIdle;
  late final machine.State _stateActive;

  MagnetIntentService() {
    _buildMachines();
  }

  void _buildMachines() {
    // -------- OUTER FSM --------

    _stateFar = _outerM.newState("far");
    _stateNear = _outerM.newState("near");
    _stateBias = _outerM.newState("bias");

    _stateNear.onEntry(() {
      _stateActive.enter();
    });

    _stateBias.onEntry(() {
      _activeTimer?.cancel();
      _count = 0;
    });

    // -------- INNER FSM --------

    _stateIdle = _innerM.newState("idle");
    _stateActive = _innerM.newState("active");

    _stateActive.onEntry(() {
      _startSampling(_fastSampling);

      // Immediate feedback on tap detection
      BeepService().beep();

      _count++;
      _lastActiveTime = DateTime.now();

      _activeTimer?.cancel();

      _activeTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        final diff = DateTime.now().difference(_lastActiveTime);

        if (diff >= _timeoutDuration) {
          timer.cancel();

          if (_outerM.current == _stateNear) {
            _stateBias.enter();
          } else if (_outerM.current == _stateFar) {
            _emitIntentFromCount(_count);
          }

          _count = 0;
          _stateIdle.enter();
        }
      });
    });

    _stateIdle.onEntry(() {
      _startSampling(_slowSampling);
    });
  }

  // ==========================
  // START / STOP
  // ==========================

  void init() {
    _startSampling(_slowSampling);
  }

  void dispose() {
    _sub?.cancel();
    _activeTimer?.cancel();
  }

  // ==========================
  // SENSOR HANDLER
  // ==========================

  void _onData(MagnetometerEvent event) {
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    if (!_baselineInitialized) {
      _baseline = magnitude;
      _baselineInitialized = true;
      _stateFar.enter();
      _stateIdle.enter();
      return;
    }

    // Baseline update
    if (_outerM.current == _stateFar) {
      _baseline = (_baseline * 0.998) + (magnitude * 0.002);
    } else if (_outerM.current == _stateBias) {
      _baseline = (_baseline * 0.99) + (magnitude * 0.01);
    }

    final double enterThreshold = _baseline + _enterDelta;
    final double exitThreshold = _baseline + _exitDelta;

    if (magnitude > enterThreshold) {
      if (_outerM.current == _stateFar) {
        _stateNear.enter();
      }
    } else if (magnitude < exitThreshold) {
      if (_outerM.current != _stateFar) {
        _stateFar.enter();
      }
    }
  }

  // ==========================
  // INTENT EMISSION
  // ==========================

  void _emitIntentFromCount(int count) {
    lastNavigationWasMagnet = true;
    if (count == 1) {
      NavigationIntentBus.emit(NavigationIntent.next);
    } else if (count == 2) {
      NavigationIntentBus.emit(NavigationIntent.select);
    } else if (count == 3) {
      NavigationIntentBus.emit(NavigationIntent.back);
    }
  }
}
