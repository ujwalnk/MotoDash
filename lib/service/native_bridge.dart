// Author: Ujwal N K
// Created:
// Native bridge - kotlin platform integration through channels - [assistant.launcher] and [phone.call]

import 'package:flutter/services.dart';

class AssistantBridge {
  static const MethodChannel _channel = MethodChannel('assistant.launcher');

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

class CallBridge {
  static const _channel = MethodChannel('phone.call');

  Future<void> endCall() async {
    await _channel.invokeMethod('endCall');
  }

  Future<void> setMute(bool muted) async {
    await _channel.invokeMethod('setMute', {'muted': muted});
  }

  Future<bool> isMuted() async {
    return await _channel.invokeMethod('isMuted') ?? false;
  }

  Future<void> bringToFront() async {
    await _channel.invokeMethod('bringToFront');
  }

  Future<void> startCallService() async {
    await _channel.invokeMethod('startCallService');
  }

  Future<void> stopCallService() async {
    await _channel.invokeMethod('stopCallService');
  }

  Future<bool> checkOverlayPermission() async {
    return await _channel.invokeMethod('checkOverlayPermission') ?? false;
  }

  Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }
}
