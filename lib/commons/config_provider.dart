// Author: Ujwal N K
// Created On: 05 Feb, 2026
// All configuration defaults are defined here to maintain a consistent list.

import 'package:flutter/material.dart' show Color, Colors;
import 'package:moto_dash/commons/constants.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

class ConfigProvider {
  static SharedPreferences? prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static bool get getIsFirstRun => prefs?.getBool(Constants.kKeyIsFirstRun) ?? true;

  // Get colors
  static Color get getBackgroundColor => Color(prefs?.getInt(Constants.kKeyBackgroundColor) ?? Colors.black.toARGB32());
  static Color get getBorderColor => Color(prefs?.getInt(Constants.kKeyBorderColor) ?? Colors.white.toARGB32());
  static Color get getFontColor => Color(prefs?.getInt(Constants.kKeyFontColor) ?? Colors.white.toARGB32());

  /// Get menu style (icon, label / abbreviated)
  static bool get getShowIcons => prefs?.getBool(Constants.kKeyShowMenuIcons) ?? true;
  static bool get getShowLabel => prefs?.getBool(Constants.kKeyShowMenuLabel) ?? true;
  static bool get getShowLabelMasked => prefs?.getBool(Constants.kKeyShowMenuLabelAbbreviated) ?? true;

  static double get getFontSize => prefs?.getDouble(Constants.kKeyFontSize) ?? 16;

  static bool get getEnableMagnetGestures => prefs?.getBool(Constants.kKeyEnableMagnetGestures) ?? false;

  // TODO: Add screen timeout, keep_screen_blank, favourite contacts & brightness
}
