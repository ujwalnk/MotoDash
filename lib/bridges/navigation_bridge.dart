// Author: Ujwal N K /w ChatGPT
// Created: 2026.07.28

import 'package:flutter/services.dart';

class NavigationBridge {
  static const MethodChannel _notification_channel = MethodChannel('in.madilu.motodash/navigation');
  static const EventChannel _events_channel = EventChannel("in.madilu.motodash/navigation_events");

  static Future<void> navigateTo(double latitude, double longitude) async {
    await _notification_channel.invokeMethod('startNavigation', {'lat': latitude, 'lng': longitude});
  }

  static Future<Map<String, dynamic>?> getDirections() async {
    final result = await _notification_channel.invokeMethod("getNavigationState");

    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  static Future<void> invokeAction(String action) async {
    await _notification_channel.invokeMethod("invokeNavigationAction", {"action": action});
  }

  static Future<void> exitNavigation() async {
    invokeAction("Exit navigation");
  }

  static Future<bool> isNavigationActive() async {
    final state = await getDirections();
    return state != null;
  }

  static Stream<Map<String, dynamic>?> get navigationStream {
    return _events_channel.receiveBroadcastStream().map((event) {
      if (event == null) {
        return null;
      }

      return Map<String, dynamic>.from(event);
    });
  }
}
