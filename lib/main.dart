// Author: Ujwal N K
// Created On: 2025, Dec 07

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/navigation_graph.dart' show NavigationGraph, CurrentPage;
import 'package:moto_dash/screen_root.dart';
import 'package:moto_dash/screen_saver.dart';
import 'package:moto_dash/screen_settings.dart';
import 'package:moto_dash/service/global_services.dart';
import 'package:moto_dash/service/magnet_navigation_controller.dart';
import 'package:moto_dash/service/native_bridge.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Holds a pending action when the navigator isn't ready yet
String? _pendingNotificationAction;

void _handlePendingNotificationAction() {
  final actionId = _pendingNotificationAction;
  if (actionId == null) return;

  final navigator = navigatorKey.currentState;
  if (navigator == null) return; // Will be retried on next resume/frame

  _pendingNotificationAction = null; // Clear only after we know we can handle it

  if (actionId == 'action_settings') {
    debugPrint("Opening Settings");
    navigator.pushNamed(Constants.kPathSettings);
    showMotoDashNotification();
  } else if (actionId == 'action_exit') {
    magnetService.stop();
    SystemNavigator.pop();
  }
}

/// Called when app is in foreground or background (but NOT terminated)
@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) {
  final actionId = response.actionId;
  if (actionId == null) return;

  debugPrint("Notification action received: $actionId");
  _pendingNotificationAction = actionId;
  _handlePendingNotificationAction();
}

/// Called when app is fully terminated and user taps a notification action
@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
  final actionId = response.actionId;
  if (actionId == null) return;

  debugPrint("Background notification action received: $actionId");
  _pendingNotificationAction = actionId;
  // Navigator won't be ready here — _MotoDashState.initState will retry
}

Future<void> showMotoDashNotification() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'moto_dash_channel',
    'Moto Dash Navigation',
    channelDescription: 'Quick navigation controls for Moto Dash',
    importance: Importance.low,
    priority: Priority.low,
    ongoing: true,
    autoCancel: false,
    actions: [
      AndroidNotificationAction('action_settings', 'Settings', showsUserInterface: true),
      AndroidNotificationAction('action_exit', 'Exit', showsUserInterface: true),
    ],
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(categoryIdentifier: 'moto_dash_actions');

  const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

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
  _initCallStateListener();

  final call = CallBridge();
  if (!await call.checkOverlayPermission()) {
    await call.requestOverlayPermission();
  }

  debugPrint("Started Magnet Intent Detection");
  magnetService.start();
  MagnetNavigationController.instance.start();

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  final List<DarwinNotificationCategory> darwinNotificationCategories = [
    DarwinNotificationCategory(
      'moto_dash_actions',
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
    onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
  );

  await showMotoDashNotification();

  runApp(const MotoDash());
}

void _initCallStateListener() {
  PhoneState.stream.listen((state) {
    if (state.status == PhoneStateStatus.CALL_ENDED || state.status == PhoneStateStatus.NOTHING) {
      if (NavigationGraph.instance.page == CurrentPage.callActPage) {
        NavigationGraph.instance.pop();
      }
      CallBridge().stopCallService();
    }
  });
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

    // Retry after the first frame — navigator is guaranteed to be mounted by then
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePendingNotificationAction();
    });
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
      // Retry in case an action arrived while the app was paused
      _handlePendingNotificationAction();
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
