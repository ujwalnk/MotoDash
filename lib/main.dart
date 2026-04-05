// Author: Ujwal N K
// Created On: 2025, Dec 07

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';
import 'package:moto_dash/navigation_graph.dart' show NavigationGraph;
import 'package:moto_dash/screen_root.dart';
import 'package:moto_dash/screen_saver.dart';
import 'package:moto_dash/service/magnet_navigation_controller.dart';
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
import 'package:moto_dash/service/global_services.dart';

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

  // Start global magnet service once
  // if (ConfigProvider.getEnableMagnetGestures) {
  // debugPrint("Started Magnet Intent Detection");
  magnetService.start();
  MagnetNavigationController.instance.start();
  // magnetService.setEnabled(true);
  // } else {
  // magnetService.setEnabled(false);
  // }

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

  void _onTaskData(dynamic data) {
    if (data is Map && data['action'] == 'settings') {
      navigatorKey.currentState?.pushNamed(Constants.kPathSettings);
    }
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);

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
