// Author: Ujwal N K
// Created On: 05 Feb, 2026
// All Constants of the Application

abstract class AppConfig {
  static const String appName = "MotoDash";
}

abstract class PrefKeys {
  static const String isFirstRun = "is_first_run";
  static const String showVolumeTip = 'show_volume_tip';
  static const String favouriteContactNames = 'favourite_contact_names';

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
  static const String riderGesturesTapDelay = "rider_gestures_tap_delay";
  static const String riderGesturesTtsOnBtOnly = "rider_gestures_tts_on_bt_only";
}

abstract class AppRoutes {
  static const dashboard = "/home";
  static const screenSaver = "/saver";
  static const screenSaverBlank = "/saver_blank";
  static const settings = "/settings";
}
