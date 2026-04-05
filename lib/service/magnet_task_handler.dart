// Author: Ujwal N K
// Creted: 2026, Mar 24

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:moto_dash/service/global_services.dart';
import 'package:moto_dash/service/magnet_navigation_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

@pragma('vm:entry-point')
class MagnetTaskHandler extends TaskHandler {
  // -------------------------
  // SERVICE START
  // -------------------------

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Runs in background isolate
    WidgetsFlutterBinding.ensureInitialized();

    DartPluginRegistrant.ensureInitialized();
  }

  // -------------------------
  // REPEAT EVENT (required in v9)
  // -------------------------

  @override
  void onRepeatEvent(DateTime timestamp) {
    // You can leave this empty
    // or use it later for heartbeat/logging
  }

  // -------------------------
  // SERVICE DESTROY
  // -------------------------

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    MagnetNavigationController.instance.stop();
    magnetService.stop();
  }

  // -------------------------
  // NOTIFICATION BUTTONS
  // -------------------------

  @override
  Future<void> onNotificationButtonPressed(String id) async {
    if (id == 'settings') {
      FlutterForegroundTask.sendDataToMain({'action': 'settings'});
      FlutterForegroundTask.launchApp();
    } else if (id == 'exit') {
      await FlutterForegroundTask.stopService();
      WakelockPlus.disable();
    }
  }
}
