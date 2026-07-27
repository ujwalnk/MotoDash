// Author: Ujwal N K
// Created: 2026.07.12
// "Rider Gestures" settings section: magnet detection + bluetooth TTS options.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/settings_tiles.dart';
import 'package:moto_dash/controllers/bt_hid_intent_detector/hid_keys_manager.dart';
import 'package:moto_dash/screens/screen_setting/sections/ble_keys_manager.dart';
import 'package:moto_dash/screens/screen_setting/setting_card.dart';
import 'package:sensors_plus/sensors_plus.dart';

class RiderGesturesSettingsSection extends StatefulWidget {
  const RiderGesturesSettingsSection({super.key});

  @override
  State<RiderGesturesSettingsSection> createState() => _RiderGesturesSettingsSectionState();
}

class _RiderGesturesSettingsSectionState extends State<RiderGesturesSettingsSection> {
  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: "Rider Gestures",
      children: [
        PrefSwitchTile(
          title: "Use magnet",
          prefKey: PrefKeys.riderGesturesMagnetEnable,
          defaultValue: false,
          onChanged: (_) => setState(() {}),
        ),
        if (ConfigProvider.riderGesturesMagnetEnabled) ...[
          const PrefTextFieldTile(
            label: "Magnet Detection Threshold (µT)",
            prefKey: PrefKeys.riderGesturesMagnetStrength,
            defaultValue: "",
            inputType: TextInputType.number,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: StreamBuilder<MagnetometerEvent>(
              stream: magnetometerEventStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text(
                    "Current Reading: -- µT",
                    style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
                  );
                }

                final event = snapshot.data!;

                final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

                return Text(
                  "Current Reading: ${magnitude.toStringAsFixed(0)} µT",
                  style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              "Tune detection for stronger or weaker magnets. A gesture is detected when the magnetic field exceeds this value."
              "\n\nBring the magnet near the phone and set the threshold to about 80% of the measured value. Adjust as needed for reliable gesture detection. "
              "\nSee the Moto Dash website for more information.",
              style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
            ),
          ),

          const PrefTextFieldTile(
            label: "Multi-Tap Window (ms)",
            prefKey: PrefKeys.riderGesturesMagnetIntentEmissionDelay,
            defaultValue: "2000",
            inputType: TextInputType.number,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              "The delay before a gesture sequence is finalized. "
              "Lower values provide snappier feedback, while higher values give you more time "
              "to complete multi-step gestures.",
              style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
            ),
          ),
        ],
        // TODO: Move to another section
        PrefSwitchTile(
          title: "Bluetooth HID Device",
          prefKey: PrefKeys.riderGesturesBtEnable,
          defaultValue: false,
          onChanged: (_) => setState(() {}),
        ),
        if (ConfigProvider.riderGesturesBtEnabled) ...[
          const Padding(padding: EdgeInsets.only(bottom: 12), child: HidKeysManager()),
        ],
        // TODO: Move to another section
        PrefSwitchTile(
          title: "Bluetooth LE Device",
          prefKey: PrefKeys.riderGesturesBleEnable,
          defaultValue: false,
          onChanged: (_) => setState(() {}),
        ),
        if (ConfigProvider.riderGesturesBleEnabled) ...[
          const Padding(padding: EdgeInsets.only(bottom: 12), child: BleKeysManager()),
        ],
        PrefSwitchTile(title: "TTS only on bluetooth", prefKey: PrefKeys.riderGesturesTtsOnBtOnly, defaultValue: true),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            "Speak Menu selection only through bluetooth",
            style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
          ),
        ),
        PrefSwitchTile(
          title: "Exit app on Bt device disconnect",
          prefKey: PrefKeys.riderGesturesTtsOnBtOnly,
          defaultValue: false,
        ),
      ],
    );
  }
}
