// Author: Ujwal N K
// Created: 2026.07.05

import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:volume_controller/volume_controller.dart';

class AdaptiveVolumeService {
  static StreamSubscription<Position>? _locationSubscription;
  static Timer? _timer;
  static double? _currentSpeed;
  static int _volumeOffset = 0;

  static late final double _activationSpeed;
  static late final double speedInterval;
  static late final int maximumVolumeSteps;

  static Future<void> init() async {
    // Catch double starts
    if (_timer != null) return;

    // Continue updating periodically.
    _timer = Timer.periodic(
      Duration(seconds: ConfigProvider.adaptiveVolumeSamplingInterval),
      (_) async => await _changeVolume(),
    );

    _locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 0),
        ).listen((position) {
          _currentSpeed = position.speed >= 0 ? position.speed * 3.6 : null;
        });
  }

  static Future<void> _changeVolume() async {
    final double currentVolume = await VolumeController.instance.getVolume();

    if (currentVolume == 0) return;

    final double lower = _activationSpeed + (_volumeOffset - 1) * speedInterval - speedInterval / 2;
    final double upper = _activationSpeed + _volumeOffset * speedInterval + speedInterval / 2;
    final previousOffset = _volumeOffset;

    // TODO: Safety flag, to be introduced in the settings - Change volume to base, let it remain as is
    if (_currentSpeed == null) {
      await VolumeController.instance.setVolume(currentVolume - _volumeOffset);
      _volumeOffset = 0;
      return;
    }

    if (_currentSpeed! < lower) {
      _volumeOffset--;
    } else if (_currentSpeed! > upper) {
      _volumeOffset++;
    }

    _volumeOffset = _volumeOffset.clamp(0, maximumVolumeSteps);

    if (_volumeOffset > previousOffset) {
      await VolumeController.instance.setVolume(currentVolume + 0.1);
    } else if (_volumeOffset < previousOffset) {
      await VolumeController.instance.setVolume(currentVolume - 0.1);
    }
  }

  static Future<void> dispose() async {
    // Cancel timer
    _timer?.cancel();
    _timer = null;

    // Revert volume back to what it was
    final double currentVolume = await VolumeController.instance.getVolume();
    await VolumeController.instance.setVolume(currentVolume - _volumeOffset);

    // Dispose the location subscription
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }
}
