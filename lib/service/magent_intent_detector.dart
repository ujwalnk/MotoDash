import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:statemachine/statemachine.dart' as machine;

enum AppIntent { next, select, back }

class MagnetIntentService {
  final _intentController = StreamController<AppIntent>.broadcast();
  Stream<AppIntent> get intents => _intentController.stream;

  StreamSubscription<MagnetometerEvent>? _sub;

  // ==========================
  // BASELINE
  // ==========================

  double _baseline = 0;
  bool _baselineInitialized = false;

  static const double _enterDelta = 35;
  static const double _exitDelta = 15;

  // ==========================
  // TAP GROUPING
  // ==========================

  int _count = 0;
  DateTime _lastActiveTime = DateTime.now();
  Timer? _activeTimer;

  // ==========================
  // MACHINES
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

    // Enter NEAR → activate inner
    _stateNear.onEntry(() {
      _stateActive.enter();
    });

    // Enter BIAS → cancel tap + reset count
    _stateBias.onEntry(() {
      _activeTimer?.cancel();
      _count = 0;
    });

    // -------- INNER FSM --------

    _stateIdle = _innerM.newState("idle");
    _stateActive = _innerM.newState("active");

    _stateActive.onEntry(() {
      _count++;
      _lastActiveTime = DateTime.now();

      _activeTimer?.cancel();

      _activeTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        final diff = DateTime.now().difference(_lastActiveTime);

        if (diff >= const Duration(seconds: 1)) {
          timer.cancel();

          // 🔥 KEY LOGIC
          if (_outerM.current == _stateNear) {
            // Still near → environmental bias
            _stateBias.enter();
          } else if (_outerM.current == _stateFar) {
            // Legit tap
            _emitIntentFromCount(_count);
          }

          _count = 0;
          _stateIdle.enter();
        }
      });
    });

    _stateIdle.onEntry(() {
      // nothing extra
    });
  }

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
    _activeTimer?.cancel();
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

    if (!_baselineInitialized) {
      _baseline = magnitude;
      _baselineInitialized = true;
      _stateFar.enter();
      _stateIdle.enter();
      return;
    }

    // -------- BASELINE UPDATE --------

    if (_outerM.current == _stateFar) {
      _baseline = (_baseline * 0.998) + (magnitude * 0.002);
    } else if (_outerM.current == _stateBias) {
      _baseline = (_baseline * 0.99) + (magnitude * 0.01);
    }

    final enterThreshold = _baseline + _enterDelta;
    final exitThreshold = _baseline + _exitDelta;

    print(
      "Mag: ${magnitude.toStringAsFixed(1)} | "
      "Base: ${_baseline.toStringAsFixed(1)} | "
      "Enter: ${enterThreshold.toStringAsFixed(1)} | "
      "Exit: ${exitThreshold.toStringAsFixed(1)} | "
      "Outer: ${_outerM.current}",
    );

    // -------- TRANSITIONS --------

    if (magnitude > enterThreshold) {
      if (_outerM.current != _stateNear) {
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
    if (count == 1) {
      _intentController.add(AppIntent.next);
    } else if (count == 2) {
      _intentController.add(AppIntent.select);
    } else if (count >= 3) {
      _intentController.add(AppIntent.back);
    }
  }
}
