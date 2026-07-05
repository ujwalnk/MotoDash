// Author: Ujwal N K
// Created: 2026.07.05

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/services/global_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static late final GlobalKey<NavigatorState> navigatorKey;

  static String? _pendingNotificationAction; // Holds a pending action when the navigator isn't ready yet
  static const String kActionExit = "action_exit";
  static const String kActionSettings = "action_settings";

  static Future<void> init(GlobalKey<NavigatorState> key) async {
    navigatorKey = key;

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
    );

    await showMotoDashNotification();
  }

  static void handlePendingNotificationAction() {
    final actionId = _pendingNotificationAction;
    if (actionId == null) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return; // Will be retried on next resume/frame

    _pendingNotificationAction = null; // Clear only after we know we can handle it

    if (actionId == kActionSettings) {
      navigator.pushNamed(AppRoutes.settings);
      showMotoDashNotification();
    } else if (actionId == kActionExit) {
      // TODO: Move this later, to directly use the dispose from the main.dart file
      magnetIntentService.dispose();
      SystemNavigator.pop();
    }
  }

  /// Called when app is in foreground or background (but NOT terminated)
  @pragma('vm:entry-point')
  static void onDidReceiveNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId == null) return;

    _pendingNotificationAction = actionId;
    handlePendingNotificationAction();
  }

  /// Called when app is fully terminated and user taps a notification action
  @pragma('vm:entry-point')
  static void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId == null) return;

    debugPrint("Background notification action received: $actionId");
    _pendingNotificationAction = actionId;
    // Navigator won't be ready here — _MotoDashState.initState will retry
  }

  static Future<void> showMotoDashNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'moto_dash_channel',
      'Moto Dash Navigation',
      channelDescription: 'Quick navigation controls for Moto Dash',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      actions: [
        AndroidNotificationAction(kActionSettings, 'Settings', showsUserInterface: true),
        AndroidNotificationAction(kActionExit, 'Exit', showsUserInterface: true),
      ],
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'MotoDash',
      body: 'Ride safe',
      notificationDetails: platformDetails,
    );
  }
}
