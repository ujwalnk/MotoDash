// Author: Ujwal N K
// Refactored Architecture Integration

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/screens/screen_contact_picker.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../commons/settings_tiles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color scaffoldBg = Color(0xFF121212);
  static const Color cardBg = Color(0xFF1E1E1E);
  static const Color textColor = Colors.white;

  String _favouriteContactsSummary = "";

  @override
  void initState() {
    super.initState();
    _loadLayoutDependencies();
  }

  Future<void> _loadLayoutDependencies() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // _keepScreenBlankValue = prefs.getBool("keep_screen_blank") ?? false;
      _favouriteContactsSummary = prefs.getStringList(PrefKeys.favouriteContactNames)?.join(", ") ?? "";
    });
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
        padding: const EdgeInsets.all(16),
        children: [
          _dashboardSetting(),
          _displaySetting(),
          _contactsSetting(context),
          _magnetSettings(),
          _extraSettings(context),
        ],
      ),
    );
  }

  Widget _dashboardSetting() {
    return _settingsCard(
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

  Widget _displaySetting() {
    return _settingsCard(
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

  Widget _contactsSetting(BuildContext context) {
    return _settingsCard(
      title: "Phone Favourite Contacts",
      children: [
        GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const FavouriteContactsScreen()));
            _loadLayoutDependencies(); // Refresh text output representation upon screen return
          },
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white54),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _favouriteContactsSummary.isEmpty ? "Pick Favourite Contacts" : _favouriteContactsSummary,
              style: const TextStyle(color: textColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _magnetSettings() {
    return _settingsCard(
      title: "Rider Gestures",
      children: [
        PrefSwitchTile(
          title: "Enable Rider Gestures",
          prefKey: PrefKeys.riderGesturesEnable,
          defaultValue: false,
          onChanged: (_) => setState(() {}),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            "Control Moto Dash using a magnetic ring or magnet near the phone.",
            style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
          ),
        ),
        if (ConfigProvider.riderGesturesEnabled) ...[
          const PrefTextFieldTile(
            label: "Magnet Detection Threshold (µT)",
            prefKey: PrefKeys.riderGesturesStrength,
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
            prefKey: PrefKeys.riderGesturesIntentEmissionDelay,
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
          PrefSwitchTile(
            title: "TTS only on bluetooth",
            prefKey: PrefKeys.riderGesturesTtsOnBtOnly,
            defaultValue: true,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              "Speak Menu selection only through bluetooth",
              style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  Widget _extraSettings(BuildContext context) {
    return _settingsCard(
      title: "Misc",
      children: [
        PrefSwitchTile(title: "Volume Tip", prefKey: PrefKeys.showVolumeTip, defaultValue: false),
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
      ],
    );
  }

  Widget _settingsCard({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: cardBg,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
