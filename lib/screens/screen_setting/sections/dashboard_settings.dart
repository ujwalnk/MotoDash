// Author: Ujwal N K
// Created: 2026.07.12
// "Dashboard" settings section: icon/label/mask toggles, font size, colors.

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/settings_tiles.dart';
import 'package:moto_dash/screens/screen_setting/setting_card.dart';

class DashboardSettingsSection extends StatelessWidget {
  const DashboardSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: "Dashboard",
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text("Menu style", style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13)),
        ),
        PrefSwitchTile(
          title: "Show Icons",
          prefKey: PrefKeys.dashboardIcons,
          defaultValue: ConfigProvider.dashboardIcons,
        ),
        PrefSwitchTile(
          title: "Show Labels",
          prefKey: PrefKeys.dashboardLabels,
          defaultValue: ConfigProvider.dashboardLabels,
        ),
        PrefSwitchTile(
          title: "Mask Menus",
          prefKey: PrefKeys.dashboardMask,
          defaultValue: ConfigProvider.dashboardMasked,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            "Mask Menus, shows only the first letter of all the menus",
            style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
          ),
        ),
        PrefTextFieldTile(
          label: "Font Size",
          prefKey: PrefKeys.dashboardFontSize,
          defaultValue: ConfigProvider.dashboardFontSize.toString(),
          inputType: TextInputType.number,
        ),
        PrefColorTile(label: "Font Color", prefKey: PrefKeys.dashboardFontColor, defaultValue: Colors.red),
        PrefColorTile(
          label: "Background Color",
          prefKey: PrefKeys.dashboardBackgroundColor,
          defaultValue: Colors.black,
        ),
        PrefColorTile(
          label: "Border Color",
          prefKey: PrefKeys.dashboardBorderColor,
          defaultValue: Colors.red.withAlpha(60),
        ),
      ],
    );
  }
}
