// Author: Ujwal N K
// Created On: 05 Feb, 2026
// All configuration defaults are defined here to maintain a consistent list.

import 'package:flutter/material.dart' show Color, Colors;
import 'package:moto_dash/commons/constants.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

/// Provides centralized access to persisted application configuration values.
///
/// Reads settings from [prefs] using keys defined in [PrefKeys] and exposes typed getters with fallback defaults
/// when no persisted value exists.
///
/// Side effects: None.
///
/// State mutations: None.
///
/// External variables modified: None.
///
/// Async behavior:
/// Requires [init] to be awaited before accessing configuration values, as [prefs] is initialized asynchronously using
/// [SharedPreferences.getInstance].
class ConfigProvider {
  static late final SharedPreferences prefs;

  /// Initializes [prefs] with the application's shared preferences instance.
  /// Must be awaited before accessing any configuration getter that depends on [prefs].
  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static bool get isFirstRun => prefs.getBool(PrefKeys.isFirstRun) ?? true;

  static bool get showVolumeTip => prefs.getBool(PrefKeys.showVolumeTip) ?? false;

  // -------------------------------------------------------------------------------------------------------------------
  // Dashboard
  // -------------------------------------------------------------------------------------------------------------------

  static Color get dashboardBackgroundColor =>
      Color(prefs.getInt(PrefKeys.dashboardBackgroundColor) ?? Colors.black.toARGB32());

  static Color get dashboardBorderColor => Color(prefs.getInt(PrefKeys.dashboardBorderColor) ?? Colors.red.toARGB32());

  static Color get dashboardFontColor => Color(prefs.getInt(PrefKeys.dashboardFontColor) ?? Colors.red.toARGB32());

  static bool get dashboardIcons => prefs.getBool(PrefKeys.dashboardIcons) ?? true;

  static bool get dashboardLabels => prefs.getBool(PrefKeys.dashboardLabels) ?? true;

  static bool get dashboardMasked => prefs.getBool(PrefKeys.dashboardMask) ?? false;

  static double get dashboardFontSize => prefs.getDouble(PrefKeys.dashboardFontSize) ?? 30;

  // -------------------------------------------------------------------------------------------------------------------
  // Display
  // -------------------------------------------------------------------------------------------------------------------

  static double get displayBrightness => prefs.getDouble(PrefKeys.displayBrightness) ?? 0;

  static bool get screenSaverEnabled => prefs.getBool(PrefKeys.displayScreenSaverEnable) ?? true;

  static int get screenSaverTimeout => prefs.getDouble(PrefKeys.displayScreenSaverTimeout)?.toInt() ?? 60;

  static bool get screenSaverAnimation => prefs.getBool(PrefKeys.displayScreenSaverAnimation) ?? true;

  // -------------------------------------------------------------------------------------------------------------------
  // Rider gestures
  // -------------------------------------------------------------------------------------------------------------------

  static bool get riderGesturesEnabled => prefs.getBool(PrefKeys.riderGesturesEnable) ?? false;

  static double get riderGesturesStrength => prefs.getDouble(PrefKeys.riderGesturesStrength) ?? 1000.0;

  static double get riderGesturesTapDelay => prefs.getDouble(PrefKeys.riderGesturesIntentEmissionDelay) ?? 2000.0;

  static bool get riderGesturesTtsOnBtOnly => prefs.getBool(PrefKeys.riderGesturesTtsOnBtOnly) ?? true;

  // -------------------------------------------------------------------------------------------------------------------
  // Adaptive Volume
  // -------------------------------------------------------------------------------------------------------------------

  static bool get adaptiveVolumeEnabled => prefs.getBool(PrefKeys.adaptiveVolumeEnable) ?? false;

  static double get adaptiveVolumeSpeedInterval => prefs.getDouble(PrefKeys.adaptiveVolumeSpeedInterval) ?? 10.0;

  static int get adaptiveVolumeMaxSteps => prefs.getDouble(PrefKeys.adaptiveVolumeMaxSteps)?.toInt() ?? 3;

  static int get adaptiveVolumeActivateMinSpeed =>
      prefs.getDouble(PrefKeys.adaptiveVolumeActivateMinSpeed)?.toInt() ?? 50;

  static int get adaptiveVolumeSamplingInterval => prefs.getDouble(PrefKeys.adaptiveVolumeSpeedInterval)?.toInt() ?? 3;

  // -------------------------------------------------------------------------------------------------------------------
  // Miscellaneous
  // -------------------------------------------------------------------------------------------------------------------

  static int get miscMaxCallLogsListed => prefs.getDouble(PrefKeys.miscMaxCallLogsListed)?.toInt() ?? 5;
}
