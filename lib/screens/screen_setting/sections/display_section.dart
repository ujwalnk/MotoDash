// Author: Ujwal N K
// Created: 2026.07.12
// "Display" settings section: brightness slider + screen saver options.

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/settings_tiles.dart';
import 'package:moto_dash/screens/screen_setting/setting_card.dart';

class DisplaySettingsSection extends StatefulWidget {
  const DisplaySettingsSection({super.key});

  @override
  State<DisplaySettingsSection> createState() => _DisplaySettingsSectionState();
}

class _DisplaySettingsSectionState extends State<DisplaySettingsSection> {
  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: "Display",
      children: [
        PrefSliderTile(title: "Brightness", prefKey: PrefKeys.displayBrightness, defaultValue: 0.0),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            "Set to 0 to use automatic brightness.",
            style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
          ),
        ),
        PrefSwitchTile(
          title: "Screen saver",
          prefKey: PrefKeys.displayScreenSaverEnable,
          defaultValue: true,
          onChanged: (_) => setState(() {}),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            "Recommended to prevent AMOLED screen burn-in",
            style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
          ),
        ),
        if (ConfigProvider.screenSaverEnabled) ...[
          PrefTextFieldTile(
            label: "Screen Saver Timeout (s)",
            prefKey: PrefKeys.displayScreenSaverTimeout,
            defaultValue: "60",
            inputType: TextInputType.number,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              "Time of inactivity before the screen saver appears.",
              style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
            ),
          ),
          PrefSwitchTile(
            title: "Animated Screen Saver",
            prefKey: PrefKeys.displayScreenSaverAnimation,
            defaultValue: true,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              "Uses a moving dot instead of a blank screen.",
              style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}
