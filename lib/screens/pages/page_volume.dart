// Author: Ujwal N K
// Created: 2026.03.22
// DashScreen - Volume controls

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/commons/dash_page.dart';
import 'package:volume_controller/volume_controller.dart';

class PageVolume extends DashPage {
  @override
  Future<void> init() async {}

  /// Builds the set of dashboard actions for controlling system audio volume.
  ///
  /// Returns a list of [DashAction] objects that increase, decrease, or toggle the mute state of the device volume using
  /// [VolumeController.instance].
  ///
  /// Side effects:
  /// Reads and modifies the system audio volume and mute state through
  /// [VolumeController.instance].
  ///
  /// State mutations: None.
  ///
  /// External variables modified: None.
  ///
  /// Navigation: None.
  ///
  /// Async behavior:
  /// Returns a [Future] that completes with the constructed list of [DashAction] objects. Each action callback performs
  /// asynchronous volume operations when invoked. Volume adjustments are clamped to the range 0.0 to 1.0
  @override
  Future<List<DashAction>> buildActions() async {
    return [
      DashAction(
        label: 'Increase Volume',
        icons: [Icons.add_rounded],
        action: () async {
          final current = await VolumeController.instance.getVolume();
          await VolumeController.instance.setVolume((current + 0.1).clamp(0.0, 1.0));
        },
      ),
      DashAction(
        label: 'Decrease Volume',
        icons: [Icons.remove_rounded],
        action: () async {
          final current = await VolumeController.instance.getVolume();
          await VolumeController.instance.setVolume((current - 0.1).clamp(0.0, 1.0));
        },
      ),
      DashAction(
        label: 'Mute / Unmute',
        icons: [Icons.volume_off_rounded],
        action: () async {
          final isMuted = await VolumeController.instance.isMuted();
          await VolumeController.instance.setMute(!isMuted);
        },
      ),
    ];
  }
}
