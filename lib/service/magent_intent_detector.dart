import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

enum AppIntent { next, select, back }

class MagnetIntentService {
  final _intentController = StreamController<AppIntent>.broadcast();
  Stream<AppIntent> get intents => _intentController.stream;

  StreamSubscription<MagnetometerEvent>? _sub;

  // ==========================
  // TAP LOGIC (UNCHANGED CORE)
  // ==========================

  int _count = 0;
  DateTime _lastActiveTime = DateTime.now();
  Timer? _activeCheckTimer;

  bool _isNear = false;

  // ==========================
  // BASELINE
  // ==========================

  double _baseline = 0;
  bool _baselineInitialized = false;

  static const double _enterDelta = 35;
  static const double _exitDelta = 15;

  // ==========================
  // BIAS MODE
  // ==========================

  bool _biasMode = false;

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

    if (!_baselineInitialized) {
      _baseline = magnitude;
      _baselineInitialized = true;
      return;
    }

    // -------------------------
    // Baseline Update
    // -------------------------

    if (!_isNear) {
      _baseline = (_baseline * 0.998) + (magnitude * 0.002);
    } else if (_biasMode) {
      // Adapt to environmental magnetic bias
      _baseline = (_baseline * 0.99) + (magnitude * 0.01);
    }

    final enterThreshold = _baseline + _enterDelta;
    final exitThreshold = _baseline + _exitDelta;

    // print(
    //   "Mag: ${magnitude.toStringAsFixed(1)} | "
    //   "Base: ${_baseline.toStringAsFixed(1)} | "
    //   "Enter: ${enterThreshold.toStringAsFixed(1)} | "
    //   "Exit: ${exitThreshold.toStringAsFixed(1)} | "
    //   "Near: $_isNear | Bias: $_biasMode",
    // );

    // ==========================
    // NEAR DETECTION
    // ==========================

    if (magnitude > enterThreshold) {
      if (!_isNear) {
        _isNear = true;
        _biasMode = false; // reset bias on fresh near
        _onEnterActive();
      }
    }
    // ==========================
    // FAR DETECTION
    // ==========================
    else if (magnitude < exitThreshold) {
      if (_isNear) {
        _isNear = false;
        _biasMode = false;
      }
    }
  }

  // ==========================
  // TAP GROUPING (KEY CHANGE)
  // ==========================

  void _onEnterActive() {
    _count++;
    _lastActiveTime = DateTime.now();

    _activeCheckTimer?.cancel();

    _activeCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      final diff = DateTime.now().difference(_lastActiveTime);

      if (diff >= const Duration(seconds: 1)) {
        timer.cancel();

        // IMPORTANT CHANGE:
        // Only emit if magnet is NOT still near
        if (!_isNear) {
          _emitIntentFromCount(_count);
        } else {
          // Magnet still near at timeout → bias
          _biasMode = true;
        }

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
    } else if (count == 2) {
      _intentController.add(AppIntent.select);
    } else if (count >= 3) {
      _intentController.add(AppIntent.back);
    }
  }
}
