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
  static const String riderGesturesStrength = "rider_gestures_strength";
  static const String riderGesturesIntentEmissionDelay = "rider_gestures_intent_emission_delay";
  static const String riderGesturesTtsOnBtOnly = "rider_gestures_tts_on_bt_only";

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
