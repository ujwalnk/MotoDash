// Author: Ujwal N K
// Created On: 05 Feb, 2026
// All Constants of the Application

/// Defines application-wide configuration constants.
///
/// Provides a centralized location for immutable values that are shared across the application.
///
/// Side effects:None.
///
/// State mutations: None.
///
/// External variables modified: None.
abstract class AppConfig {
  static const String appName = "MotoDash";
}

/// Defines keys used to persist and retrieve application settings.
///
/// The constants in this class are used as identifiers for values stored in persistent storage.
///
/// Side effects: None.
///
/// State mutations: None.
///
/// External variables modified: None.
abstract class PrefKeys {
  static const String isFirstRun = "is_first_run";
  // static const String favouriteContactNames = "favourite_contact_names";

  // Dashboard Domain
  static const String dashboardBackgroundColor = 'dashboard_background_color';
  static const String dashboardBorderColor = 'dashboard_border_color';
  static const String dashboardFontColor = 'dashboard_font_color';
  static const String dashboardFontSize = 'dashboard_font_size';
  static const String dashboardIcons = 'dashboard_icons';
  static const String dashboardLabels = 'dashboard_label';
  static const String dashboardMask = 'dashboard_mask';
  static const String dashboardStatusBar = "dashboard_status_bar";

  // Display / Screensaver Domain
  static const String displayBrightness = "display_brightness";
  static const String displayScreenSaverEnable = "display_screen_saver_enable";
  static const String displayScreenSaverTimeout = "display_screen_saver_timeout";
  static const String displayScreenSaverAnimation = "display_screen_saver_animation";

  // Phone favourite contacts
  static const String phoneFavContactNames = "phone_favourite_contact_names";
  static const String phoneFavContactNumbers = "phone_favourite_contact_numbers";

  // Rider Gestures Domain
  static const String riderGesturesEnable = "rider_gestures_enable";
  static const String riderGesturesTtsOnBtOnly = "rider_gestures_tts_on_bt_only";
  static const String riderGesturesExitOnBtDisconnect = "rider_gestures_exit_on_bt_disconnect";
  static const String riderGesturesExitOnBtDisconnectDelay = "rider_gestures_exit_on_bt_disconnect_delay";

  // Rider Gestures Bluetooth HID sub domain
  static const String riderGesturesBtEnable = "rider_gestures_bt_enable";
  static const String riderGesturesHidBtKeys = 'rider_gestures_hid_keys'; // TODO: Rename to BtKeys remove HID
  static const String riderGesturesBtIntentEmissionDelay = "rider_gestures_bt_intent_emission_delay";

  // Rider Gestures BLE sub domain
  static const String riderGesturesBleEnable = "rider_gestures_ble_enable";
  static const String riderGesturesBleDeviceId = "rider_gestures_ble_device_id";
  static const String riderGesturesBleDeviceName = "rider_gestures_ble_device_name";
  static const String riderGesturesBleServiceUuid = "rider_gestures_ble_service_uuid";
  static const String riderGesturesBleCharacteristicUuid = "rider_gestures_ble_characteristic_uuid";
  static const String riderGesturesBleKeys = "rider_gestures_ble_keys";
  static const String riderGesturesBleIntentEmissionDelay = "rider_gestures_ble_intent_emission_delay";

  // Rider Gestures Magnet sub domain
  static const String riderGesturesMagnetEnable = "rider_gestures_magnet_enable";
  static const String riderGesturesMagnetStrength = "rider_gestures_magnet_strength";
  static const String riderGesturesMagnetIntentEmissionDelay = "rider_gestures_magnet_intent_emission_delay";

  // Adaptive Volume Domain
  static const String adaptiveVolumeEnable = "misc_adaptive_volume_enable";
  static const String adaptiveVolumeSpeedInterval = "adaptive_volume_speed_interval";
  static const String adaptiveVolumeMaxSteps = "adaptive_volume_max_steps";
  static const String adaptiveVolumeActivateMinSpeed = "adaptive_volume_activate_min_speed";
  static const String adaptiveVolumeSamplingInterval = "adaptive_volume_sampling_interval";

  // Miscellaneous
  static const String showVolumeTip = "misc_show_volume_tip";
  static const String miscMaxCallLogsListed = "misc_max_call_logs_listed";
  static const String miscSwapMusicButtonPositions = "misc_swap_music_button_position";
}

abstract class BleConstants {
  /// Must match SERVICE_UUID in the ESP32 firmware.
  static const String motoDashRemoteServiceUuid = "12345678-1234-1234-1234-1234567890ab";

  /// Must match CHARACTERISTIC_UUID in the ESP32 firmware.
  static const String motoDashRemoteCharacteristicUuid = "87654321-4321-4321-4321-ba0987654321";
}

/// Defines the named route paths used for application navigation.
///
/// Provides a centralized list of route identifiers used by the navigation system.
///
/// Side effects: None.
///
/// State mutations: None.
///
/// External variables modified: None.
abstract class AppRoutes {
  static const String grantPermission = "/setup/permissions";
  static const settings = "/settings";

  static const dashboard = "/home";

  static const screenSaver = "/saver";
  static const screenSaverBlank = "/saver_blank";
}
