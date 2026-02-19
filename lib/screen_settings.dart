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
  Color BorderColor = Colors.grey;
  final fontSizeController = TextEditingController();

  // Brightness
  double brightness = 50;

  static const Color settingsScreenFontColor = Color(0xFFF2F2F7);

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
      BorderColor = ConfigProvider.getBorderColor;
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

    // await prefs.setString("phone_favourite_contacts", favouriteContacts);

    await prefs.setDouble(Constants.kKeyBrightness, brightness);

    await prefs.setBool("keep_screen_blank", keepScreenBlank);
    await prefs.setString("blank_time_minutes", blankTimeController.text);

    await prefs.setInt(Constants.kKeyFontColor, fontColor.toARGB32());
    await prefs.setInt(
      Constants.kKeyBackgroundColor,
      backgroundColor.toARGB32(),
    );
    await prefs.setInt(Constants.kKeyBorderColor, BorderColor.toARGB32());
    await prefs.setString(Constants.kKeyFontSize, fontSizeController.text);
    await prefs.setBool(
      Constants.kKeyEnableMagnetGestures,
      magnetGesturesEnabled,
    );
  }

  // ------------------------------------------------------------
  // UI WIDGETS
  // ------------------------------------------------------------

  Widget sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: settingsScreenFontColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> showRgbPicker({
    required Color currentColor,
    required ValueChanged<Color> onColorSelected,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => HexWheelColorPickerDialog(
        color: currentColor,
        onChanged: (c) {
          onColorSelected(c);
        },
      ),
    );
  }

  Widget checkboxTile(String title, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: TextStyle(color: settingsScreenFontColor)),
      value: value,
      onChanged: (v) => onChanged(v!),
      activeColor: settingsScreenFontColor,
      checkColor: Colors.black,
      contentPadding: EdgeInsets.zero,
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
        style: const TextStyle(color: settingsScreenFontColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: settingsScreenFontColor),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: settingsScreenFontColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: settingsScreenFontColor),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: settingsScreenFontColor),
        ),
        child: Text(
          display,
          style: TextStyle(
            color: value.isEmpty
                ? settingsScreenFontColor
                : settingsScreenFontColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget colorTile({
    required String label,
    required Color color,
    required ValueChanged<Color> onColorSelected,
  }) {
    return GestureDetector(
      onTap: () =>
          showRgbPicker(currentColor: color, onColorSelected: onColorSelected),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: settingsScreenFontColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: settingsScreenFontColor)),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: settingsScreenFontColor),
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
      backgroundColor: Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: Color(0xFF1C1C1E),
        title: Text(
          "Settings",
          style: TextStyle(color: settingsScreenFontColor),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await saveSettings();

              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: Text(
              "Save",
              style: TextStyle(color: settingsScreenFontColor),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // HOME
          sectionHeader("Home Screen"),
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

          // MUSIC
          sectionHeader("Music Screen"),
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

          // VOLUME
          sectionHeader("Volume Screen"),
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

          // PHONE
          sectionHeader("Phone Favourite Contacts"),
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

          // BRIGHTNESS
          sectionHeader("Screen Brightness (O for auto)"),
          Slider(
            value: brightness,
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: (v) => setState(() => brightness = v),
          ),
          Text(
            "${brightness.toInt()}%",
            style: TextStyle(color: settingsScreenFontColor),
          ),

          // BLANK SCREEN
          sectionHeader("Blank Screen Settings"),
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

          // GENERAL
          sectionHeader("General Settings"),
          // textField("Font Color (Hex)", fontColorController),
          // textField("Background Color (Hex)", backgroundColorController),
          // textField("Option Border Color (Hex)", optionBorderColorController),
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
            label: "Option Border Color",
            color: BorderColor,
            onColorSelected: (c) => setState(() => BorderColor = c),
          ),

          // Experimental Settings
          sectionHeader("Experimental Settings"),
          checkboxTile(
            "Enable Magnet Gestures",
            magnetGesturesEnabled,
            (v) => setState(() => magnetGesturesEnabled = v),
          ),
        ],
      ),
    );
  }
}
