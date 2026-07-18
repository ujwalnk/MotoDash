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
  static const String favouriteContactNames = "favourite_contact_names";

  // Dashboard Domain
  static const String dashboardBackgroundColor = 'dashboard_background_color';
  static const String dashboardBorderColor = 'dashboard_border_color';
  static const String dashboardFontColor = 'dashboard_font_color';
  static const String dashboardFontSize = 'dashboard_font_size';
  static const String dashboardIcons = 'dashboard_icons';
  static const String dashboardLabels = 'dashboard_label';
  static const String dashboardMask = 'dashboard_mask';

  // Display / Screensaver Domain
  static const String displayBrightness = "display_brightness";
  static const String displayScreenSaverEnable = "display_screen_saver_enable";
  static const String displayScreenSaverTimeout = "display_screen_saver_timeout";
  static const String displayScreenSaverAnimation = "display_screen_saver_animation";

  // Rider Gestures Domain
  static const String riderGesturesEnable = "rider_gestures_enable";
  static const String riderGesturesTtsOnBtOnly = "rider_gestures_tts_on_bt_only";

  // Rider Gestures Bluetooth HID sub domain
  static const String riderGesturesBtEnable = "rider_gestures_bt_enable";
  static const String riderGesturesHidBtKeys = 'rider_gestures_hid_keys'; // TODO: Rename to BtKeys remove HID
  static const String riderGesturesBtIntentEmissionDelay = "rider_gestures_bt_intent_emission_delay";

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
