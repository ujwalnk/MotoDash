// Author: Ujwal N K
// Created On: 05 Feb, 2026
// All Option Defaults are defined here to consistantly maintain a list.

import 'package:flutter/material.dart' show Color, Colors, debugPrint;
import 'package:moto_dash/commons/constants.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

class ConfigProvider {
  static SharedPreferences? prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static bool get getIsFirstRun {
    return prefs?.getBool(Constants.kKeyIsFirstRun) ?? true;
  }

  static Color get getBackgroundColor {
    return Color(
      prefs?.getInt(Constants.kKeyBackgroundColor) ?? Colors.black.toARGB32(),
    );
  }

  static Color get getFontColor {
    return Color(
      prefs?.getInt(Constants.kKeyFontColor) ?? Colors.white.toARGB32(),
    );
  }

  static Color get getBorderColor {
    return Color(
      prefs?.getInt(Constants.kKeyBorderColor) ?? Colors.white.toARGB32(),
    );
  }

  static bool getShowIcons(String path) {
    switch (path) {
      case Constants.kPathHome:
        return prefs?.getBool(Constants.kKeyHomeShowIcons) ?? true;
      case Constants.kPathMusic:
        return prefs?.getBool(Constants.kKeyMusicShowIcons) ?? true;
      case Constants.kPathVolume:
        return prefs?.getBool(Constants.kKeyVolumeShowIcons) ?? true;
      default:
        return true;
    }
  }

  static bool getShowLabel(String path) {
    switch (path) {
      case Constants.kPathHome:
        return prefs?.getBool(Constants.kKeyHomeShowLabel) ?? true;
      case Constants.kPathMusic:
        return prefs?.getBool(Constants.kKeyMusicShowLabel) ?? true;
      case Constants.kPathVolume:
        return prefs?.getBool(Constants.kKeyVolumeShowLabel) ?? true;
      default:
        return true;
    }
  }

  static double get getFontSize {
    return prefs?.getDouble(Constants.kKeyFontSize) ?? 16;
  }

  static bool get getEnableMagnetGestures {
    debugPrint(
      "Magnet Gestures: ${prefs!.getBool(Constants.kKeyEnableMagnetGestures)}",
    );
    return prefs?.getBool(Constants.kKeyEnableMagnetGestures) ?? false;
  }
}
