import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Home screen settings
  bool homeShowIcons = false;
  bool homeShowLabel = false;

  // Music screen settings
  bool musicShowIcons = false;
  bool musicShowLabel = false;

  // Volume screen settings
  bool volumeShowIcons = false;
  bool volumeShowLabel = false;

  // Phone screen settings
  String favouriteContacts = "";

  // General settings
  final fontColorController = TextEditingController();
  final backgroundColorController = TextEditingController();
  final optionBorderColorController = TextEditingController();
  final fontSizeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -------------------------- HOME SCREEN --------------------------
          sectionHeader("Home Screen"),
          checkboxTile(
            title: "Show Icons",
            value: homeShowIcons,
            onChanged: (v) => setState(() => homeShowIcons = v),
          ),
          checkboxTile(
            title: "Show Label",
            value: homeShowLabel,
            onChanged: (v) => setState(() => homeShowLabel = v),
          ),

          // -------------------------- MUSIC SCREEN --------------------------
          sectionHeader("Music Screen"),
          checkboxTile(
            title: "Show Icons",
            value: musicShowIcons,
            onChanged: (v) => setState(() => musicShowIcons = v),
          ),
          checkboxTile(
            title: "Show Label",
            value: musicShowLabel,
            onChanged: (v) => setState(() => musicShowLabel = v),
          ),

          // -------------------------- VOLUME SCREEN --------------------------
          sectionHeader("Volume Screen"),
          checkboxTile(
            title: "Show Icons",
            value: volumeShowIcons,
            onChanged: (v) => setState(() => volumeShowIcons = v),
          ),
          checkboxTile(
            title: "Show Label",
            value: volumeShowLabel,
            onChanged: (v) => setState(() => volumeShowLabel = v),
          ),

          // -------------------------- PHONE SCREEN --------------------------
          sectionHeader("Phone Screen"),
          textInput(
            controller: favouriteContacts,
            label: "Pick Favourite Contacts",
            onTap: () {
              // TODO: Add contact picker action
            },
            readOnly: true,
          ),

          // -------------------------- GENERAL SETTINGS --------------------------
          sectionHeader("General Settings"),
          textField("Font Color (Hex)", fontColorController),
          textField("Background Color (Hex)", backgroundColorController),
          textField("Option Border Color (Hex)", optionBorderColorController),
          textField("Font Size", fontSizeController, inputType: TextInputType.number),
        ],
      ),
    );
  }

  // Header widget
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

  // Checkbox widget
  Widget checkboxTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: (v) => onChanged(v!),
      activeColor: Colors.white,
      checkColor: Colors.black,
      contentPadding: EdgeInsets.zero,
    );
  }

  // Standard text field
  Widget textField(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text}) {
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

  // Fake input for "Pick Favourite Contacts"
  Widget textInput({
    required String label,
    required String controller,
    required VoidCallback onTap,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white54),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            controller.isEmpty ? label : controller,
            style: TextStyle(
              color: controller.isEmpty ? Colors.white54 : Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
