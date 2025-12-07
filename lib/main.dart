import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';

import 'package:moto_dash/screen_call_fav.dart';
import 'package:moto_dash/screen_call_recents.dart';
import 'package:moto_dash/screen_home.dart';
import 'package:moto_dash/screen_music.dart';
import 'package:moto_dash/screen_saver.dart';
import 'package:moto_dash/screen_settings.dart';
import 'package:moto_dash/screen_volume.dart';
import 'package:moto_dash/service/timer.dart';
import 'package:moto_dash/service/transitions.dart';

import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request notification listener permission
  await FlutterMediaController.requestPermissions();

  // Set Fullscreen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  // Set Brightness
  await ScreenBrightness.instance.setApplicationScreenBrightness(0.3);

  // Don't show system volume UI
  VolumeController.instance.showSystemUI = true;

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

    // Enable idle timer after home loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      IdleTimer.instance.setEnabled(true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WakelockPlus.enable();
      IdleTimer.instance.resetTimer(); // 🟢 Reset when returning
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,

      // 🟢 Detect touch activity globally
      onPointerDown: (_) => IdleTimer.instance.registerActivity(),
      onPointerMove: (_) => IdleTimer.instance.registerActivity(),
      onPointerHover: (_) => IdleTimer.instance.registerActivity(),

      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        initialRoute: '/home',
        navigatorKey: navigatorKey,

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
          '/home': (_) => const HomeScreen(),
          '/phone_log': (_) => const CallLogScreen(),
          '/phone_fav': (_) => const FavContactsScreen(),
          '/music': (_) => const MusicScreen(),
          '/volume': (_) => const VolumeScreen(),
          '/settings': (_) => const SettingsScreen(),

          // 🟢 Add your blank/black saver screen here
          '/saver': (_) => const ScreenSaver(),
        },

        builder: (context, child) {
          // 🟢 Allow IdleTimer to access global navigation context
          IdleTimer.instance.initialize(navigatorKey);

          return child!;
        },
      ),
    );
  }
}
