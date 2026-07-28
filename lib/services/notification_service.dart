// Author: Ujwal N K
// Created: 2026.07.05

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/controllers/ble_hid_intent_detector/ble_hid_bridge.dart';
import 'package:moto_dash/services/global_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static late final GlobalKey<NavigatorState> navigatorKey;

  static String? _pendingNotificationAction; // Holds a pending action when the navigator isn't ready yet
  static const String kActionExit = "action_exit";
  static const String kActionSettings = "action_settings";
  static const String kActionConnectBle = "action_connect_ble";

  /// Last-known BLE connection status line shown under the notification's main body. Null means
  /// "nothing to report" (BLE disabled, or never attempted), so the body falls back to just
  /// "Ride safe".
  static String? _connectionStatus;

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
    if (actionId == kActionConnectBle) {
      _handleConnectBleAction();
    }
    if (navigator == null) return; // Will be retried on next resume/frame

    _pendingNotificationAction = null; // Clear only after we know we can handle it

    if (actionId == kActionSettings) {
      navigator.pushNamed(AppRoutes.settings);
      showMotoDashNotification();
    } else if (actionId == kActionExit) {
      // TODO: Move this later, to directly use the dispose from the main.dart file
      magnetIntentService.terminate();
      SystemNavigator.pop();
    }
  }

  /// Turns Bluetooth on if needed and reconnects to the saved BLE remote, reporting the outcome
  /// via a toast and updating the notification's status line. Never touches the navigator/UI, so
  /// it's safe to fire from a tapped action with `showsUserInterface: false` - including when the
  /// app is fully terminated.
  static Future<void> _handleConnectBleAction() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await ConfigProvider.init();

      final deviceName = await BleHidBridge.instance.connectToSavedDevice();

      await Fluttertoast.showToast(
        msg: deviceName != null ? "Connected to $deviceName" : "Couldn't connect to the BLE remote",
      );

      await updateConnectionStatus(deviceName != null ? "Connected to $deviceName" : "Not connected");
    } catch (e) {
      try {
        await Fluttertoast.showToast(msg: "Connect action failed: $e");
      } catch (_) {}
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

    if (actionId == kActionConnectBle) {
      _handleConnectBleAction();
      return;
    }

    debugPrint("Background notification action received: $actionId");
    _pendingNotificationAction = actionId;
    // Navigator won't be ready here — _MotoDashState.initState will retry
  }

  /// Updates the status line shown in the notification body (e.g. "Connected to MotoDash
  /// Remote") and re-renders it in place. Pass null to clear it back to the plain default body.
  static Future<void> updateConnectionStatus(String? status) async {
    _connectionStatus = status;
    await showMotoDashNotification();
  }

  static Future<void> showMotoDashNotification() async {
    final bool showConnectAction =
        ConfigProvider.riderGesturesBleEnabled && ConfigProvider.riderGesturesBleDeviceId != null;

    final List<AndroidNotificationAction> actions = [
      if (showConnectAction) const AndroidNotificationAction(kActionConnectBle, 'Connect', showsUserInterface: true),
      const AndroidNotificationAction(kActionSettings, 'Settings', showsUserInterface: true),
      const AndroidNotificationAction(kActionExit, 'Exit', showsUserInterface: true),
    ];

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'moto_dash_channel',
      'Moto Dash Navigation',
      channelDescription: 'Quick navigation controls for Moto Dash',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      actions: actions,
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'MotoDash',
      body: _connectionStatus != null ? 'Ride safe • $_connectionStatus' : 'Ride safe',
      notificationDetails: platformDetails,
    );
  }
}
