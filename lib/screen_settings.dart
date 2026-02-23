// Author: Ujwal N K
// Created On: 10 Feb, 2026

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moto_dash/service/contact_picker.dart';
import 'package:moto_dash/service/rgb_color_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Home screen
  bool homeShowIcons = false;
  bool homeShowLabel = false;

  // Music screen
  bool musicShowIcons = false;
  bool musicShowLabel = false;

  // Volume screen
  bool volumeShowIcons = false;
  bool volumeShowLabel = false;

  // Magnetic Gestures
  bool magnetGesturesEnabled = false;

  // Phone
  String favouriteContactNames = "";

  // Blank screen settings
  bool keepScreenBlank = false;
  final blankTimeController = TextEditingController();

  // General settings
  Color fontColor = Colors.white;
  Color backgroundColor = Colors.black;
  Color borderColor = Colors.grey;
  final fontSizeController = TextEditingController();

  // Brightness
  double brightness = 50;

  static const Color scaffoldBg = Color(0xFF121212);
  static const Color cardBg = Color(0xFF1E1E1E);
  static const Color textColor = Colors.white;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  // ------------------------------------------------------------
  // LOAD ALL SETTINGS FROM SHARED PREFERENCES
  // ------------------------------------------------------------
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      homeShowIcons = ConfigProvider.getShowIcons(Constants.kPathHome);
      homeShowLabel = ConfigProvider.getShowLabel(Constants.kPathHome);

      musicShowIcons = ConfigProvider.getShowIcons(Constants.kPathMusic);
      musicShowLabel = ConfigProvider.getShowLabel(Constants.kPathMusic);

      volumeShowIcons = ConfigProvider.getShowIcons(Constants.kPathVolume);
      volumeShowLabel = ConfigProvider.getShowLabel(Constants.kPathVolume);

      brightness = prefs.getDouble(Constants.kKeyBrightness) ?? 50.0;

      keepScreenBlank = prefs.getBool("keep_screen_blank") ?? false;
      blankTimeController.text = prefs.getString("blank_time_minutes") ?? "";

      fontSizeController.text = ConfigProvider.getFontSize.toString();

      backgroundColor = ConfigProvider.getBackgroundColor;
      borderColor = ConfigProvider.getBorderColor;
      fontColor = ConfigProvider.getFontColor;

      favouriteContactNames =
          prefs.getStringList(Constants.kKeyFavContactNames)?.join(", ") ?? "";

      magnetGesturesEnabled = ConfigProvider.getEnableMagnetGestures;
    });
  }

  // ------------------------------------------------------------
  // SAVE ALL SETTINGS TO SHARED PREFERENCES
  // ------------------------------------------------------------
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(Constants.kKeyHomeShowIcons, homeShowIcons);
    await prefs.setBool(Constants.kKeyHomeShowLabel, homeShowLabel);

    await prefs.setBool(Constants.kKeyMusicShowIcons, musicShowIcons);
    await prefs.setBool(Constants.kKeyMusicShowLabel, musicShowLabel);

    await prefs.setBool(Constants.kKeyVolumeShowIcons, volumeShowIcons);
    await prefs.setBool(Constants.kKeyVolumeShowLabel, volumeShowLabel);

    await prefs.setDouble(Constants.kKeyBrightness, brightness);

    await prefs.setBool("keep_screen_blank", keepScreenBlank);
    await prefs.setString("blank_time_minutes", blankTimeController.text);

    await prefs.setInt(Constants.kKeyFontColor, fontColor.toARGB32());
    await prefs.setInt(
      Constants.kKeyBackgroundColor,
      backgroundColor.toARGB32(),
    );
    await prefs.setInt(Constants.kKeyBorderColor, borderColor.toARGB32());

    await prefs.setDouble(
      Constants.kKeyFontSize,
      double.parse(fontSizeController.text),
    );

    await prefs.setBool(
      Constants.kKeyEnableMagnetGestures,
      magnetGesturesEnabled,
    );
  }

  Widget _settingsCard({
    required String title,
    required List<Widget> children,
  }) {
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
                style: const TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget checkboxTile(String title, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: TextStyle(color: textColor)),
      value: value,
      onChanged: (v) => onChanged(v!),
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.blueGrey,
      checkColor: Colors.black,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }

  Widget textField(
    String label,
    TextEditingController controller, {
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        style: const TextStyle(color: textColor),
        decoration: const InputDecoration(
          labelStyle: TextStyle(color: textColor),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueGrey),
          ),
        ),
      ),
    );
  }

  Widget tappableField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final display = value.isEmpty ? label : value;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(display, style: const TextStyle(color: textColor)),
      ),
    );
  }

  Widget colorTile({
    required String label,
    required Color color,
    required ValueChanged<Color> onColorSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (_) => HexWheelColorPickerDialog(
            color: color,
            onChanged: onColorSelected,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: textColor)),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        foregroundColor: textColor,
        title: const Text("Settings"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              await saveSettings();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Colors.blueGrey)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _settingsCard(
            title: "Home Screen",
            children: [
              checkboxTile(
                "Show Icons",
                homeShowIcons,
                (v) => setState(() => homeShowIcons = v),
              ),
              checkboxTile(
                "Show Label",
                homeShowLabel,
                (v) => setState(() => homeShowLabel = v),
              ),
            ],
          ),
          _settingsCard(
            title: "Music Screen",
            children: [
              checkboxTile(
                "Show Icons",
                musicShowIcons,
                (v) => setState(() => musicShowIcons = v),
              ),
              checkboxTile(
                "Show Label",
                musicShowLabel,
                (v) => setState(() => musicShowLabel = v),
              ),
            ],
          ),
          _settingsCard(
            title: "Volume Screen",
            children: [
              checkboxTile(
                "Show Icons",
                volumeShowIcons,
                (v) => setState(() => volumeShowIcons = v),
              ),
              checkboxTile(
                "Show Label",
                volumeShowLabel,
                (v) => setState(() => volumeShowLabel = v),
              ),
            ],
          ),
          _settingsCard(
            title: "Phone Favourite Contacts",
            children: [
              tappableField(
                label: "Pick Favourite Contacts",
                value: favouriteContactNames,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FavouriteContactsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          _settingsCard(
            title: "Screen Brightness (0 for auto)",
            children: [
              Slider(
                value: brightness,
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: (v) => setState(() => brightness = v),
              ),
              Text(
                "${brightness.toInt()}%",
                style: const TextStyle(color: textColor),
              ),
            ],
          ),
          _settingsCard(
            title: "Blank Screen Settings",
            children: [
              checkboxTile(
                "Keep screen blank & wake on single tap",
                keepScreenBlank,
                (v) => setState(() => keepScreenBlank = v),
              ),
              if (keepScreenBlank)
                textField(
                  "Blank Time (Minutes)",
                  blankTimeController,
                  inputType: TextInputType.number,
                ),
            ],
          ),
          _settingsCard(
            title: "General Settings",
            children: [
              textField(
                "Font Size",
                fontSizeController,
                inputType: TextInputType.number,
              ),
              colorTile(
                label: "Font Color",
                color: fontColor,
                onColorSelected: (c) => setState(() => fontColor = c),
              ),
              colorTile(
                label: "Background Color",
                color: backgroundColor,
                onColorSelected: (c) => setState(() => backgroundColor = c),
              ),
              colorTile(
                label: "Border Color",
                color: borderColor,
                onColorSelected: (c) => setState(() => borderColor = c),
              ),
            ],
          ),
          _settingsCard(
            title: "Experimental Settings",
            children: [
              checkboxTile(
                "Enable Magnet Gestures",
                magnetGesturesEnabled,
                (v) => setState(() => magnetGesturesEnabled = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
