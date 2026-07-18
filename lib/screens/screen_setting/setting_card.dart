// Author: Ujwal N K
// Reusable expandable card used by every settings menu section.

import 'package:flutter/material.dart';

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  static const Color cardBg = Color(0xFF1E1E1E);
  static const Color textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: cardBg,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: textColor,
          collapsedIconColor: textColor,
          title: Text(
            title,
            style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          children: children,
        ),
      ),
    );
  }
}
