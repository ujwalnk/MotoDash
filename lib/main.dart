// Author: Ujwal N K
// Created On: 2025, Dec 07

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/navigation_graph.dart' show NavigationGraph;
import 'package:moto_dash/screen_root.dart';
import 'package:moto_dash/screen_saver.dart';
import 'package:moto_dash/screen_settings.dart';
import 'package:moto_dash/service/global_services.dart';
import 'package:moto_dash/service/magnet_navigation_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

/// Handle notification interaction
@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) {
  final actionId = response.actionId;

  // Route based on which button was pressed on the notification
  // Handle Settings Button Click
  if (actionId == 'action_settings') {
    print("Opening Settings");
    navigatorKey.currentState?.pushNamed(Constants.kPathSettings);
  }
  // Handle Exit Button Click
  else if (actionId == 'action_exit') {
    // Stop the magnet services to prevent memory leaks or rogue background loops
    magnetService.stop();

    // Gracefully pop the top-level Flutter activity and close the app
    SystemNavigator.pop();
  }
}

Future<void> showMotoDashNotification() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'moto_dash_channel',
    'Moto Dash Navigation',
    channelDescription: 'Quick navigation controls for Moto Dash',
    importance: Importance.max,
    priority: Priority.high,
    actions: [
      AndroidNotificationAction('action_settings', 'Settings'),
      AndroidNotificationAction('action_exit', 'Exit'),
    ],
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(categoryIdentifier: 'moto_dash_actions');

  const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

  // To this:
  await flutterLocalNotificationsPlugin.show(
    id: 0,
    title: 'MotoDash',
    body: 'Ride safe',
    notificationDetails: platformDetails,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await ConfigProvider.init();

  if (ConfigProvider.getIsFirstRun == true) {
    await FlutterMediaController.requestPermissions();
    await prefs.setBool(Constants.kKeyIsFirstRun, false);
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  if (prefs.getDouble("brightness") != null && prefs.getDouble("brightness") != 0) {
    await ScreenBrightness.instance.setApplicationScreenBrightness(prefs.getDouble("brightness")! / 100);
  } else {
    await ScreenBrightness.instance.resetApplicationScreenBrightness();
  }

  var status = await Permission.phone.status;
  if (!status.isGranted) {
    status = await Permission.phone.request();
    if (!status.isGranted) return;
  }

  VolumeController.instance.showSystemUI = true;

  // Start global magnet service once
  // if (ConfigProvider.getEnableMagnetGestures) {
  debugPrint("Started Magnet Intent Detection");
  magnetService.start();
  MagnetNavigationController.instance.start();
  // magnetService.setEnabled(true);
  // } else {
  // magnetService.setEnabled(false);
  // }

  // Ensure you have an icon named 'ic_launcher' in android/app/src/main/res/mipmap...
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  final List<DarwinNotificationCategory> darwinNotificationCategories = [
    DarwinNotificationCategory(
      'moto_dash_actions', // Category ID
      actions: [
        DarwinNotificationAction.plain('action_settings', 'Settings'),
        DarwinNotificationAction.plain('action_exit', 'Exit'),
      ],
    ),
  ];

  final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    notificationCategories: darwinNotificationCategories,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );

  await showMotoDashNotification();

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
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    magnetService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WakelockPlus.enable();
    } else if (state == AppLifecycleState.paused) {
      WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavigationGraph.instance,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        home: const RootScreen(),
        theme: ThemeData(fontFamily: 'AtkinsonHyperlegible'),
        routes: {
          Constants.kPathSettings: (_) => const SettingsScreen(),
          Constants.kPathScreenSaver: (_) => const ScreenSaver(),
        },
      ),
    );
  }
}
