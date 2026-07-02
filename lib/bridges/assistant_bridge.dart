// Author: Ujwal N K
// Created: 2026.06.29
// Bridge for assistant related features

import 'package:flutter/services.dart';

class AssistantBridge {
  static const MethodChannel _channel = MethodChannel('in.madilu.motodash/assistant');

  static Future<bool> launch() async {
    try {
      await _channel.invokeMethod('launchAssistant');
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isBluetoothConnected() async {
    return await _channel.invokeMethod('isBluetoothConnected') ?? false;
  }
}
