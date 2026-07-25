// Author: Ujwal N K
// Created On: 2025.12.07

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart' show Settings, SharePreferenceCache;
import 'package:moto_dash/commons/call_state.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/controllers/bt_hid_intent_detector/bt_intent_detector.dart';
import 'package:moto_dash/controllers/navigation_intent_handler.dart';
import 'package:moto_dash/navigation_graph.dart' show NavigationGraph;
import 'package:moto_dash/screens/screen_permissions.dart';
import 'package:moto_dash/screens/screen_root.dart';
import 'package:moto_dash/screens/screen_saver.dart';
import 'package:moto_dash/screens/screen_saver_blank.dart';
import 'package:moto_dash/screens/screen_setting/screen_settings.dart';
import 'package:moto_dash/services/adaptive_volume_service.dart';
import 'package:moto_dash/services/global_service.dart';
import 'package:moto_dash/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'controllers/ble_hid_intent_detector/ble_intent_detector.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool showSetupScreen = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await ConfigProvider.init();
  await NotificationService.init(navigatorKey);
  await Settings.init(cacheProvider: SharePreferenceCache());
  NavigationIntentHandler.instance.init();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  VolumeController.instance.showSystemUI = ConfigProvider.showVolumeTip;

  ConfigProvider.displayBrightness != 0
      ? await ScreenBrightness.instance.setApplicationScreenBrightness(ConfigProvider.displayBrightness / 100)
      : await ScreenBrightness.instance.resetApplicationScreenBrightness();

  if (ConfigProvider.isFirstRun) {
    showSetupScreen = true;
    await prefs.setBool(PrefKeys.isFirstRun, false);
  }

  runApp(const MotoDash());
}

class MotoDash extends StatefulWidget {
  const MotoDash({super.key});

  @override
  State<MotoDash> createState() => _MotoDashState();
}

class _MotoDashState extends State<MotoDash> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Get all the services up and running
    AdaptiveVolumeService.init();
    BleIntentDetector.init();
    BtIntentDetector.init();
    CallStateListener.init();
    WakelockPlus.enable();

    // Retry after the first frame — navigator is guaranteed to be mounted by then
    WidgetsBinding.instance.addPostFrameCallback((_) => NotificationService.handlePendingNotificationAction());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Clean disposal of all the services
    AdaptiveVolumeService.dispose();
    BleIntentDetector.dispose();
    BtIntentDetector.dispose();
    CallStateListener.dispose();
    WakelockPlus.disable();
    magnetIntentService.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WakelockPlus.enable();
      NotificationService.handlePendingNotificationAction(); // Retry in case an action arrived while the app was paused
    } else if (state == AppLifecycleState.paused) {
      WakelockPlus.disable();
    }
  }

  /// Builds the root application widget tree.
  ///
  /// Provides [NavigationGraph.instance] to descendants via [ChangeNotifierProvider] and configures the application's
  /// [MaterialApp], including [navigatorKey], theme, initial screen, and named routes defined by [AppRoutes.settings],
  /// [AppRoutes.screenSaver], and [AppRoutes.screenSaverBlank].
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavigationGraph.instance,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: showSetupScreen ? const PermissionsScreen() : const RootScreen(),
        theme: ThemeData(fontFamily: 'AtkinsonHyperlegible'),
        onGenerateRoute: router,
      ),
    );
  }

  Route<dynamic>? router(settings) {
    final Widget page = switch (settings.name) {
      AppRoutes.grantPermission => const PermissionsScreen(),
      AppRoutes.settings => const SettingsScreen(),
      AppRoutes.screenSaver => const ScreenSaver(),
      AppRoutes.screenSaverBlank => const ScreenSaverBlank(),
      AppRoutes.dashboard => const RootScreen(),
      _ => throw Exception('Unknown route: ${settings.name}'),
    };

    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
