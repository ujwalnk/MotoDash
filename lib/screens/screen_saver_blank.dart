// Author: Ujwal N K
// Created: 16.06.2026
// Blank screen saver

import 'package:flutter/material.dart';

class ScreenSaverBlank extends StatelessWidget {
  const ScreenSaverBlank({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => Navigator.of(context).pop(),
      child: Scaffold(backgroundColor: Colors.black),
    );
  }
}
