// Author: Ujwal N K
// Created: 2026.07.12
// "Phone Favourite Contacts" settings section.

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/screens/screen_contact_picker.dart';
import 'package:moto_dash/screens/screen_setting/setting_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsSettingsSection extends StatefulWidget {
  const ContactsSettingsSection({super.key});

  @override
  State<ContactsSettingsSection> createState() => _ContactsSettingsSectionState();
}

class _ContactsSettingsSectionState extends State<ContactsSettingsSection> {
  static const Color textColor = Colors.white;

  String _favouriteContactsSummary = "";

  @override
  void initState() {
    super.initState();
    _loadFavouriteContacts();
  }

  Future<void> _loadFavouriteContacts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favouriteContactsSummary = prefs.getStringList(PrefKeys.favouriteContactNames)?.join(", ") ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: "Phone Favourite Contacts",
      children: [
        GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const FavouriteContactsScreen()));
            _loadFavouriteContacts(); // Refresh text output representation upon screen return
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
}
