// Author: Ujwal N K
// Settings screen: hosts the scaffold/app bar and assembles each settings
// menu section. All section-specific UI and state now lives in its own
// widget under sections/.

import 'package:flutter/material.dart';
import 'package:moto_dash/controllers/navigation_intent_handler.dart';
import 'package:moto_dash/screens/screen_setting/sections/contacts_setting.dart';
import 'package:moto_dash/screens/screen_setting/sections/dashboard_settings.dart';
import 'package:moto_dash/screens/screen_setting/sections/display_section.dart';
import 'package:moto_dash/screens/screen_setting/sections/dynamic_volume_setting.dart';
import 'package:moto_dash/screens/screen_setting/sections/misc_setting.dart';
import 'package:moto_dash/screens/screen_setting/sections/rider_gesture_setting.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color scaffoldBg = Color(0xFF121212);
  static const Color textColor = Colors.white;

  @override
  void initState() {
    super.initState();

    // Stop navigation intents
    NavigationIntentHandler.setState(false);
    Future(() async {
      debugPrint("Before: ${await WakelockPlus.enabled}");
      await WakelockPlus.disable();
      debugPrint("After : ${await WakelockPlus.enabled}");
    });
  }

  @override
  void dispose() {
    // Resume navigation intents - TODO - Check if this works properly
    NavigationIntentHandler.setState(true);
    WakelockPlus.enable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        foregroundColor: textColor,
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          DashboardSettingsSection(),
          DisplaySettingsSection(),
          ContactsSettingsSection(),
          RiderGesturesSettingsSection(),
          DynamicVolumeSettingsSection(),
          MiscSettingsSection(),
        ],
      ),
    );
  }
}
