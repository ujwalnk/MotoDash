// Author: Ujwal N K
// Created On: 2025, Dec 07

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/screen_call_fav.dart';
import 'package:moto_dash/screen_call_nav.dart';
import 'package:moto_dash/screen_call_recents.dart';
import 'package:moto_dash/screen_home.dart';
import 'package:moto_dash/screen_music.dart';
import 'package:moto_dash/screen_saver.dart';
import 'package:moto_dash/screen_settings.dart';
import 'package:moto_dash/screen_volume.dart';
import 'package:moto_dash/service/timer.dart';
import 'package:moto_dash/service/transitions.dart';
import 'package:moto_dash/service/global_services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// RouteObserver for RouteAware screens
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  if (ConfigProvider.getEnableMagnetGestures) {
    debugPrint("Started Magnet Intent Detection");
    magnetService.start();
    // magnetService.setEnabled(true);
  } else {
    // magnetService.setEnabled(false);
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
    WakelockPlus.enable();

    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    SharedPreferences.getInstance().then((prefs) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        IdleTimer.instance.setEnabled(
          prefs.getBool("keep_screen_blank") ?? false,
        );
      });
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
      IdleTimer.instance.resetTimer();
    } else if (state == AppLifecycleState.paused) {
      WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => IdleTimer.instance.registerActivity(),
      onPointerMove: (_) => IdleTimer.instance.registerActivity(),
      onPointerHover: (_) => IdleTimer.instance.registerActivity(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,

        /// Attach RouteObserver
        navigatorObservers: [routeObserver],

        initialRoute: Constants.kPathHome,
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: NoTransitionsBuilder(),
              TargetPlatform.iOS: NoTransitionsBuilder(),
              TargetPlatform.linux: NoTransitionsBuilder(),
              TargetPlatform.macOS: NoTransitionsBuilder(),
              TargetPlatform.windows: NoTransitionsBuilder(),
            },
          ),
        ),
        routes: {
          Constants.kPathHome: (_) => const HomeScreen(),
          Constants.kPathCallNav: (_) => const CallNavScreen(),
          Constants.kPathCallLog: (_) => const CallLogScreen(),
          Constants.kPathCallFav: (_) => const FavContactsScreen(),
          Constants.kPathMusic: (_) => const MusicScreen(),
          Constants.kPathVolume: (_) => const VolumeScreen(),
          Constants.kPathScreenSaver: (_) => const ScreenSaver(),
          Constants.kPathSettings: (_) => const SettingsScreen(),
        },
        builder: (context, child) {
          IdleTimer.instance.initialize(navigatorKey);
          return child!;
        },
      ),
    );
  }
}
