import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:moto_dash/service/contact_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Phone
  String favouriteContacts = "";

  // Blank screen settings
  bool keepScreenBlank = false;
  final blankTimeController = TextEditingController();

  // General settings
  // final fontColorController = TextEditingController();
  // final backgroundColorController = TextEditingController();
  // final optionBorderColorController = TextEditingController();
  Color fontColor = Colors.white;
  Color backgroundColor = Colors.black;
  Color optionBorderColor = Colors.grey;
  final fontSizeController = TextEditingController();

  // Brightness
  double brightness = 50;

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
      homeShowIcons = prefs.getBool("home_show_icons") ?? false;
      homeShowLabel = prefs.getBool("home_show_label") ?? false;

      musicShowIcons = prefs.getBool("music_show_icons") ?? false;
      musicShowLabel = prefs.getBool("music_show_label") ?? false;

      volumeShowIcons = prefs.getBool("volume_show_icons") ?? false;
      volumeShowLabel = prefs.getBool("volume_show_label") ?? false;

      favouriteContacts = prefs.getString("phone_favourite_contacts") ?? "";

      brightness = prefs.getDouble("brightness") ?? 50.0;

      keepScreenBlank = prefs.getBool("keep_screen_blank") ?? false;
      blankTimeController.text = prefs.getString("blank_time_minutes") ?? "";

      // fontColorController.text = prefs.getString("font_color") ?? "";
      // backgroundColorController.text =
      //     prefs.getString("background_color") ?? "";
      // optionBorderColorController.text =
      //     prefs.getString("option_border_color") ?? "";
      fontSizeController.text = prefs.getString("font_size") ?? "";

      fontColor = Color(prefs.getInt("font_color") ?? Colors.white.toARGB32());

      backgroundColor = Color(
        prefs.getInt("background_color") ?? Colors.black.toARGB32(),
      );

      optionBorderColor = Color(
        prefs.getInt("option_border_color") ?? Colors.grey.toARGB32(),
      );
    });
  }

  // ------------------------------------------------------------
  // SAVE ALL SETTINGS TO SHARED PREFERENCES
  // ------------------------------------------------------------
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool("home_show_icons", homeShowIcons);
    await prefs.setBool("home_show_label", homeShowLabel);

    await prefs.setBool("music_show_icons", musicShowIcons);
    await prefs.setBool("music_show_label", musicShowLabel);

    await prefs.setBool("volume_show_icons", volumeShowIcons);
    await prefs.setBool("volume_show_label", volumeShowLabel);

    await prefs.setString("phone_favourite_contacts", favouriteContacts);

    await prefs.setDouble("brightness", brightness);

    await prefs.setBool("keep_screen_blank", keepScreenBlank);
    await prefs.setString("blank_time_minutes", blankTimeController.text);

    // await prefs.setString("font_color", fontColorController.text);
    await prefs.setInt("font_color", fontColor.toARGB32());
    await prefs.setInt("background_color", backgroundColor.toARGB32());
    await prefs.setInt("option_border_color", optionBorderColor.toARGB32());
    await prefs.setString("font_size", fontSizeController.text);
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
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget checkboxTile(String title, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: (v) => onChanged(v!),
      activeColor: Colors.white,
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
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
        decoration: BoxDecoration(border: Border.all(color: Colors.white54)),
        child: Text(
          display,
          style: TextStyle(
            color: value.isEmpty ? Colors.white54 : Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> showColorPickerDialog({
    required Color currentColor,
    required ValueChanged<Color> onColorSelected,
  }) async {
    Color pickerColor = currentColor;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Pick a Color',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                setState(() => pickerColor = color);
              },
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                onColorSelected(pickerColor);
                Navigator.of(context).pop();
              },
              child: const Text("Got it"),
            ),
          ],
        );
      },
    );
  }

  Widget colorTile({
    required String label,
    required Color color,
    required ValueChanged<Color> onColorSelected,
  }) {
    return GestureDetector(
      onTap: () => showColorPickerDialog(
        currentColor: color,
        onColorSelected: onColorSelected,
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.white54)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white)),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () async {
              await saveSettings();
              Navigator.pop(context); // finished
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
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
          sectionHeader("Phone Screen"),
          tappableField(
            label: "Pick Favourite Contacts",
            value: favouriteContacts,
            onTap: () async {
              final selected = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ContactPickerScreen(
                    preSelected: favouriteContacts.split(","),
                  ),
                ),
              );

              if (selected != null && selected is List<String>) {
                setState(() {
                  favouriteContacts = selected.join(",");
                });
              }
            },
          ),

          // BRIGHTNESS
          sectionHeader("Screen Brightness"),
          Slider(
            value: brightness,
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: (v) => setState(() => brightness = v),
          ),
          Text(
            "${brightness.toInt()}%",
            style: const TextStyle(color: Colors.white),
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
            color: optionBorderColor,
            onColorSelected: (c) => setState(() => optionBorderColor = c),
          ),
        ],
      ),
    );
  }
}
