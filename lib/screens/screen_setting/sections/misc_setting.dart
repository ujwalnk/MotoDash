// Author: Ujwal N K
// Created: 2026.07.12
// "Misc" settings section: volume tip + call log list length.

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/settings_tiles.dart';
import 'package:moto_dash/screens/onboarding/screen_onboarding.dart';
import 'package:moto_dash/screens/screen_setting/setting_card.dart';

class MiscSettingsSection extends StatelessWidget {
  const MiscSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: "Misc",
      children: [
        PrefSwitchTile(
          title: "Volume Tip",
          prefKey: PrefKeys.showVolumeTip,
          defaultValue: ConfigProvider.showVolumeTip,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            "Display the volume slider when volume changes.",
            style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
          ),
        ),
        const PrefTextFieldTile(
          label: "Maximum listed call logs",
          prefKey: PrefKeys.miscMaxCallLogsListed,
          defaultValue: "5",
          inputType: TextInputType.number,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            "Number of recent calls to display. \nHigher values show more call logs but make the buttons smaller. "
            "Lower values make buttons larger and easier to use. The call log screen does not support scrolling.",
            style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
          ),
        ),
        PrefSwitchTile(
          title: "Swap Previous & play/pause key position",
          prefKey: PrefKeys.miscSwapMusicButtonPositions,
          defaultValue: ConfigProvider.miscSwapMusicButtonPositions,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const OnboardingScreen(), fullscreenDialog: true)),
            icon: const Icon(Icons.replay_rounded, color: Colors.white),
            label: const Text("Replay first-run setup", style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
