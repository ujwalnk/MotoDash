// Author: Ujwal N K
// Created: 2026, Mar 22

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/dash_action.dart';
import 'package:volume_controller/volume_controller.dart';

Future<List<DashAction>> buildVolumeActions() async {
  return [
    DashAction(
      label: 'Increase Volume',
      icons: [Icons.add_rounded],
      action: () async {
        final current = await VolumeController.instance.getVolume();
        await VolumeController.instance.setVolume(
          (current + 0.1).clamp(0.0, 1.0),
        );
      },
    ),
    DashAction(
      label: 'Decrease Volume',
      icons: [Icons.remove_rounded],
      action: () async {
        final current = await VolumeController.instance.getVolume();
        await VolumeController.instance.setVolume(
          (current - 0.1).clamp(0.0, 1.0),
        );
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
