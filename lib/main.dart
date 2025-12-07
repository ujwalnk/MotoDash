import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';

import 'package:moto_dash/screen_home.dart';
import 'package:moto_dash/screen_music.dart';
import 'package:moto_dash/screen_settings.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request notification listener permission
  await FlutterMediaController.requestPermissions();

  // Set Fullscreen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  // Set Brightness
  await ScreenBrightness.instance.setApplicationScreenBrightness(0.3);

  // Don't show system volume UI
  VolumeController.instance.showSystemUI = false;

  runApp(const MotoDash());
}

class MotoDash extends StatefulWidget {
  const MotoDash({super.key});

  @override
  State<MotoDash> createState() => _MotoDashState();
}

class _MotoDashState extends State<MotoDash>
    with WidgetsBindingObserver {
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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/home',
      routes: {
        '/home': (_) => const HomeScreen(),
        '/music': (_) => const MusicScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

