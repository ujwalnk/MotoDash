// Author: Ujwal N K
// Created On: 2025, Dec 07

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';
import 'package:moto_dash/menu_actions.dart';
import 'package:moto_dash/navigation_graph.dart';
import 'package:moto_dash/screen_root.dart';
import 'package:moto_dash/screen_saver.dart';
import 'package:moto_dash/service/magnet_task_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/screen_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'moto_dash_service',
      channelName: 'MotoDash Service',
      channelDescription: 'Magnet gesture navigation',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      autoRunOnBoot: false,
    ),
  );

  await FlutterForegroundTask.requestNotificationPermission();

  final prefs = await SharedPreferences.getInstance();
  await ConfigProvider.init();

  if (ConfigProvider.getIsFirstRun == true) {
    await FlutterMediaController.requestPermissions();
    await prefs.setBool(Constants.kKeyIsFirstRun, false);
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  if (prefs.getDouble("brightness") != null &&
      prefs.getDouble("brightness") != 0) {
    await ScreenBrightness.instance.setApplicationScreenBrightness(
      prefs.getDouble("brightness")! / 100,
    );
  } else {
    await ScreenBrightness.instance.resetApplicationScreenBrightness();
  }

  var status = await Permission.phone.status;
  if (!status.isGranted) {
    status = await Permission.phone.request();
    if (!status.isGranted) return;
  }

  VolumeController.instance.showSystemUI = true;

  // Sensor and navigation logic now live entirely in the service isolate.
  // Do NOT start magnetService or MagnetNavigationController here.

  FlutterForegroundTask.setTaskHandler(MagnetTaskHandler());
  FlutterForegroundTask.initCommunicationPort();

  await FlutterForegroundTask.startService(
    notificationTitle: 'MotoDash - Ride Safe',
    notificationText: 'Magnet gestures active',
    notificationButtons: [
      const NotificationButton(id: 'settings', text: 'Settings'),
      const NotificationButton(id: 'exit', text: 'Exit'),
    ],
  );

  runApp(const MotoDash());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    // Do NOT stop magnetService or MagnetNavigationController here.
    // The service isolate owns them and must outlive the Activity.
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

  Future<void> _onTaskData(dynamic data) async {
    if (data is! Map) return;

    switch (data['action']) {

      // Service mirrors its NavigationGraph here so the UI shows the correct
      // page the moment the screen turns on — no catch-up needed.
      case 'page_changed':
        final pageName = data['page'] as String?;
        if (pageName == null) return;
        final page = CurrentPage.values.firstWhere(
          (e) => e.name == pageName,
          orElse: () => CurrentPage.homePage,
        );
        NavigationGraph.instance.syncPage(page);
        break;

      // Service needs the Activity to run this action (call, assistant).
      // launchApp() has already been called before this message was sent,
      // so the Activity is foregrounded and platform channels work normally.
      case 'execute_action':
        final pageName = data['page'] as String?;
        final index = data['index'] as int?;
        if (pageName == null || index == null) return;

        final page = CurrentPage.values.firstWhere(
          (e) => e.name == pageName,
          orElse: () => CurrentPage.homePage,
        );
        final builder = menuActions[page];
        if (builder == null) return;

        final items = await builder();
        if (index < items.length) items[index].action();
        break;

      // Notification button: Settings
      case 'settings':
        navigatorKey.currentState?.pushNamed(Constants.kPathSettings);
        break;

      // Notification button: Exit — stop service then kill the process
      case 'exit':
        await FlutterForegroundTask.stopService();
        WakelockPlus.disable();
        SystemNavigator.pop();
        break;
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