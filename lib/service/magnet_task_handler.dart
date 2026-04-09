// Author: Ujwal N K
// Created: 2026, Mar 24

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/navigation_graph.dart';
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
    // Both calls are required: ensureInitialized sets up the Flutter engine
    // in this isolate, and DartPluginRegistrant registers all plugins
    // (sensor_plus, volume_controller, tts, etc.) against it.
    // Without these, platform channels silently fail.
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // ConfigProvider reads SharedPreferences, which menuActions use to
    // decide which items to show (showIcons, showLabel, favourites, etc.)
    await ConfigProvider.init();

    // Sensor and navigation logic live entirely in this isolate from here on.
    // This isolate is kept alive by the foreground service regardless of
    // whether the Activity (screen) is on or off.
    magnetService.start();
    MagnetNavigationController.instance.start();

    // Mirror any page changes to the main isolate so the UI is always
    // up-to-date the moment the screen turns on.
    NavigationGraph.instance.addListener(_onPageChanged);

    debugPrint("MagnetTaskHandler started");
  }

  // -------------------------
  // PAGE CHANGE MIRROR
  // -------------------------

  void _onPageChanged() {
    FlutterForegroundTask.sendDataToMain({
      'action': 'page_changed',
      'page': NavigationGraph.instance.page.name,
    });
  }

  // -------------------------
  // REPEAT EVENT
  // -------------------------

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Intentionally empty — sensor drives everything via stream.
    // Could be used for heartbeat logging if needed.
  }

  // -------------------------
  // SERVICE DESTROY
  // -------------------------

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    NavigationGraph.instance.removeListener(_onPageChanged);
    MagnetNavigationController.instance.stop();
    magnetService.stop();
    debugPrint("MagnetTaskHandler destroyed");
  }

  // -------------------------
  // NOTIFICATION BUTTONS
  // -------------------------

  @override
  Future<void> onNotificationButtonPressed(String id) async {
    if (id == 'settings') {
      // sendDataToMain first — launchApp() brings the Activity up, and the
      // main isolate must already be listening before the data arrives.
      // Since the foreground service keeps the process alive, the main
      // isolate is always running (just paused), so the callback is registered.
      FlutterForegroundTask.sendDataToMain({'action': 'settings'});
      FlutterForegroundTask.launchApp();
    } else if (id == 'exit') {
      // Ask the main isolate to shut down — it holds the Activity context
      // needed for SystemNavigator.pop() and must clean up its own resources.
      FlutterForegroundTask.sendDataToMain({'action': 'exit'});
    }
  }
}