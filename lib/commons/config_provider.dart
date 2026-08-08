// Author: Ujwal N K
// Created On: 05 Feb, 2026
// All configuration defaults are defined here to maintain a consistent list.

import 'dart:convert';

import 'package:flutter/material.dart' show Color, Colors;
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/controllers/ble_hid_intent_detector/ble_registered_key.dart';
import 'package:moto_dash/controllers/bt_hid_intent_detector/hid_key_registry.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

import 'navigation_destination_model.dart';

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
  static bool _initialized = false;

  /// Initializes [prefs] with the application's shared preferences instance.
  /// Must be awaited before accessing any configuration getter that depends on [prefs].
  static Future<void> init() async {
    if (_initialized) return;
    prefs = await SharedPreferences.getInstance();
    _initialized = true;
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

  static bool get dashboardStatusBar => prefs.getBool(PrefKeys.dashboardStatusBar) ?? false;

  // -------------------------------------------------------------------------------------------------------------------
  // Display
  // -------------------------------------------------------------------------------------------------------------------

  static double get displayBrightness => prefs.getDouble(PrefKeys.displayBrightness) ?? 0;

  static bool get screenSaverEnabled => prefs.getBool(PrefKeys.displayScreenSaverEnable) ?? true;

  static int get screenSaverTimeout => prefs.getDouble(PrefKeys.displayScreenSaverTimeout)?.toInt() ?? 60;

  static bool get screenSaverAnimation => prefs.getBool(PrefKeys.displayScreenSaverAnimation) ?? true;

  // -------------------------------------------------------------------------------------------------------------------
  // Favourites
  // -------------------------------------------------------------------------------------------------------------------

  static List<String> get phoneFavContactNames => prefs.getStringList(PrefKeys.phoneFavContactNames) ?? [];

  static List<String> get phoneFavContactNumbers => prefs.getStringList(PrefKeys.phoneFavContactNumbers) ?? [];

  // -------------------------------------------------------------------------------------------------------------------
  // Navigation Favourites
  // -------------------------------------------------------------------------------------------------------------------

  /// All saved navigation destinations, decoded from a single JSON-encoded string dict. Returns an empty list when
  /// nothing has been saved yet.
  static List<NavigationDestinationModel> get navigationFavourites {
    final String? raw = prefs.getString(PrefKeys.navigationFavourites);
    if (raw == null || raw.isEmpty) return [];

    final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.entries.map((e) => NavigationDestinationModel.fromEntry(e.key, e.value as String)).toList();
  }

  /// Persists the entire ordered list of navigation favourites as a single JSON-encoded string dict.
  static Future<void> setNavigationFavourites(List<NavigationDestinationModel> favourites) async {
    final Map<String, String> encoded = {for (final f in favourites) f.id: f.toEntryValue()};
    await prefs.setString(PrefKeys.navigationFavourites, jsonEncode(encoded));
  }

  // -------------------------------------------------------------------------------------------------------------------
  // Rider gestures
  // -------------------------------------------------------------------------------------------------------------------

  static bool get riderGesturesTtsOnBtOnly => prefs.getBool(PrefKeys.riderGesturesTtsOnBtOnly) ?? true;

  // Rider gestures - Bluetooth HID

  static bool get riderGesturesBtEnabled => prefs.getBool(PrefKeys.riderGesturesBtEnable) ?? false;

  static int get riderGesturesBtTapDelay =>
      prefs.getDouble(PrefKeys.riderGesturesBtIntentEmissionDelay)?.toInt() ?? 250;

  /// All registered Bluetooth HID keys, decoded from a single JSON string. Returns an empty list when nothing has been
  /// registered yet.
  static List<HidRegisteredKey> get riderGesturesHidKeys {
    final String? raw = prefs.getString(PrefKeys.riderGesturesHidBtKeys);
    if (raw == null || raw.isEmpty) return [];

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => HidRegisteredKey.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Persists the entire list of registered HID keys as a single JSON string.
  static Future<void> setRiderGesturesHidKeys(List<HidRegisteredKey> keys) async {
    final String encoded = jsonEncode(keys.map((k) => k.toJson()).toList());
    await prefs.setString(PrefKeys.riderGesturesHidBtKeys, encoded);
  }

  // Rider gestures - Bluetooth LE (BLE)

  static bool get riderGesturesBleEnabled => prefs.getBool(PrefKeys.riderGesturesBleEnable) ?? false;

  static int get riderGesturesBleTapDelay =>
      prefs.getDouble(PrefKeys.riderGesturesBleIntentEmissionDelay)?.toInt() ?? 250;

  static String? get riderGesturesBleDeviceId => prefs.getString(PrefKeys.riderGesturesBleDeviceId);

  static String? get riderGesturesBleDeviceName => prefs.getString(PrefKeys.riderGesturesBleDeviceName);

  static String? get riderGesturesBleServiceUuid => prefs.getString(PrefKeys.riderGesturesBleServiceUuid);

  static String? get riderGesturesBleCharacteristicUuid => prefs.getString(PrefKeys.riderGesturesBleCharacteristicUuid);

  static Future<void> setRiderGesturesBleDevice({
    required String deviceId,
    required String deviceName,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    await prefs.setString(PrefKeys.riderGesturesBleDeviceId, deviceId);
    await prefs.setString(PrefKeys.riderGesturesBleDeviceName, deviceName);
    await prefs.setString(PrefKeys.riderGesturesBleServiceUuid, serviceUuid);
    await prefs.setString(PrefKeys.riderGesturesBleCharacteristicUuid, characteristicUuid);
  }

  static Future<void> clearRiderGesturesBleDevice() async {
    await prefs.remove(PrefKeys.riderGesturesBleDeviceId);
    await prefs.remove(PrefKeys.riderGesturesBleDeviceName);
    await prefs.remove(PrefKeys.riderGesturesBleServiceUuid);
    await prefs.remove(PrefKeys.riderGesturesBleCharacteristicUuid);
  }

  /// All registered BLE buttons, decoded from a single JSON string.
  static List<BleRegisteredKey> get riderGesturesBleKeys {
    final String? raw = prefs.getString(PrefKeys.riderGesturesBleKeys);
    if (raw == null || raw.isEmpty) return [];

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => BleRegisteredKey.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> setRiderGesturesBleKeys(List<BleRegisteredKey> keys) async {
    final String encoded = jsonEncode(keys.map((k) => k.toJson()).toList());
    await prefs.setString(PrefKeys.riderGesturesBleKeys, encoded);
  }

  // Rider gestures - Magnet
  static bool get riderGesturesMagnetEnabled => prefs.getBool(PrefKeys.riderGesturesMagnetEnable) ?? false;

  static double get riderGesturesMagnetStrength => prefs.getDouble(PrefKeys.riderGesturesMagnetStrength) ?? 1000.0;

  static double get riderGesturesMagnetTapDelay =>
      prefs.getDouble(PrefKeys.riderGesturesMagnetIntentEmissionDelay) ?? 2000.0;

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

  static bool get miscSwapMusicButtonPositions => prefs.getBool(PrefKeys.miscSwapMusicButtonPositions) ?? true;

  // -------------------------------------------------------------------------------------------------------------------
  // Feature Flags — single serialized Map<String, bool>, keyed by FeatureKeys. Every feature defaults to enabled so
  // that a fresh install (or an upgrade from before this map existed) behaves exactly as it did before.
  // -------------------------------------------------------------------------------------------------------------------

  static const Map<String, bool> _defaultFeatureFlags = {
    FeatureKeys.phone: true,
    FeatureKeys.music: true,
    FeatureKeys.navigation: true,
    FeatureKeys.assistant: true,
    FeatureKeys.voiceNotes: true,
    FeatureKeys.volumeControls: true,
  };

  /// The full enable/disable state of every MotoDash feature, decoded from a single JSON-encoded string map. Missing
  /// or unrecognized keys fall back to their default (enabled).
  static Map<String, bool> get featureFlags {
    final String? raw = prefs.getString(PrefKeys.featureFlags);
    Map<String, dynamic> decoded = {};
    if (raw != null && raw.isNotEmpty) {
      decoded = jsonDecode(raw) as Map<String, dynamic>;
    }
    return {for (final key in FeatureKeys.all) key: decoded[key] as bool? ?? _defaultFeatureFlags[key]!};
  }

  /// Persists the entire feature flag map as a single JSON-encoded string.
  static Future<void> setFeatureFlags(Map<String, bool> flags) async {
    await prefs.setString(PrefKeys.featureFlags, jsonEncode(flags));
  }

  /// Updates a single feature's enabled state, preserving every other flag.
  static Future<void> setFeatureEnabled(String feature, bool enabled) async {
    final flags = featureFlags;
    flags[feature] = enabled;
    await setFeatureFlags(flags);
  }

  static bool isFeatureEnabled(String feature) => featureFlags[feature] ?? true;

  static bool get phoneEnabled => isFeatureEnabled(FeatureKeys.phone);

  static bool get musicEnabled => isFeatureEnabled(FeatureKeys.music);

  static bool get navigationEnabled => isFeatureEnabled(FeatureKeys.navigation);

  static bool get assistantEnabled => isFeatureEnabled(FeatureKeys.assistant);

  static bool get voiceNotesEnabled => isFeatureEnabled(FeatureKeys.voiceNotes);

  static bool get volumeControlsEnabled => isFeatureEnabled(FeatureKeys.volumeControls);
}
