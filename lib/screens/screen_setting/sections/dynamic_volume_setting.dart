// Author: Ujwal N K
// Created: 2026.07.12
// "Dynamic Volume" settings section: speed-adaptive volume controls.

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/settings_tiles.dart';
import 'package:moto_dash/screens/screen_setting/setting_card.dart';

class DynamicVolumeSettingsSection extends StatefulWidget {
  const DynamicVolumeSettingsSection({super.key});

  @override
  State<DynamicVolumeSettingsSection> createState() => _DynamicVolumeSettingsSectionState();
}

class _DynamicVolumeSettingsSectionState extends State<DynamicVolumeSettingsSection> {
  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: "Dynamic Volume",
      children: [
        PrefSwitchTile(
          title: "Speed Adaptive Volume",
          prefKey: PrefKeys.adaptiveVolumeEnable,
          defaultValue: false,
          onChanged: (_) => setState(() {}),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            "Adapt device music volume based on vehicle speed",
            style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
          ),
        ),
        if (ConfigProvider.adaptiveVolumeEnabled) ...[
          const PrefTextFieldTile(
            label: "Activation Speed (km/h)",
            prefKey: PrefKeys.adaptiveVolumeSpeedInterval,
            defaultValue: "50",
            inputType: TextInputType.number,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              "The speed at which dynamic volume adjustment begins. Below this speed, your volume remains unchanged.",
              style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
            ),
          ),
          const PrefTextFieldTile(
            label: "Speed interval (km/h)",
            prefKey: PrefKeys.adaptiveVolumeSpeedInterval,
            defaultValue: "10",
            inputType: TextInputType.number,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              "The speed increase required before the volume is raised by one step. Smaller values increase the volume more frequently.\n"
              "Default: Increase the volume by one step for every 10 km/h increase in speed.",
              style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
            ),
          ),
          const PrefTextFieldTile(
            label: "Maximum volume increase (steps)",
            prefKey: PrefKeys.adaptiveVolumeMaxSteps,
            defaultValue: "3",
            inputType: TextInputType.number,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              "Specifies the maximum number of volume steps that may be applied automatically above the initial media volume.",
              style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
            ),
          ),
          PrefSliderTile(title: "Brightness", prefKey: PrefKeys.adaptiveVolumeSamplingInterval, defaultValue: 3.0),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              "Controls how gradually the media volume is adjusted in response to changes in vehicle speed.\n"
              "Higher the slider value, higher the battery consumption",
              style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}
