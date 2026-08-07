// Author: Ujwal N K
// Created: 2026.07.25
// Permission Checker

import 'package:moto_dash/screens/screen_permissions.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionCheck {
  PermissionCheck._();

  static Future<bool> get phone async => Permission.phone.isGranted;

  static Future<bool> get contacts async => Permission.contacts.isGranted;

  static Future<bool> get bluetooth async =>
      await Permission.bluetoothScan.isGranted && await Permission.bluetoothConnect.isGranted;

  static Future<bool> get notification async => Permission.notification.isGranted;

  static Future<bool> get overlay async => Permission.systemAlertWindow.isGranted;

  static Future<bool> get batteryOptimization async => Permission.ignoreBatteryOptimizations.isGranted;

  static Future<bool> get location async =>
      await Permission.location.isGranted && await Permission.locationAlways.isGranted;

  static Future<bool> get microphone async => Permission.microphone.isGranted;

  /// WRITE_EXTERNAL_STORAGE is declared with `android:maxSdkVersion="28"`
  /// in the manifest, so this permission group doesn't apply on Android
  /// 10+ and permission_handler reports it as granted automatically there
  /// — which is correct, since MediaStore's Downloads collection needs no
  /// storage permission for files the app writes itself.
  static Future<bool> get storage async => Permission.storage.isGranted;

  static Future<bool> callLog() async => NativePermissions.requestCallLog();

  static Future<void> notificationListener() async => NativePermissions.openNotificationListenerSettings();

  /// True once every permission the Voice Note feature needs is granted.
  /// Used to decide whether the Voice Note dashboard item is shown.
  static Future<bool> hasVoiceNotePermissions() async => await microphone;
}
