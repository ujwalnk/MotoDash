// Author: Ujwal N K
// Created:
// Native bridge - kotlin platform integration through channels - [assistant.launcher] and [phone.call]

import 'package:flutter/services.dart';

abstract class TelephonyBridge {
  static const _channel = MethodChannel('phone.call');

  static Future<void> answerCall() async => await _channel.invokeMethod('answerCall');

  static Future<void> endCall() async => await _channel.invokeMethod('endCall');

  static Future<void> silenceCall() async => await _channel.invokeMethod('silenceRinger');

  static Future<void> setMute(bool muted) async => await _channel.invokeMethod('setMute', {'muted': muted});

  static Future<bool> isMuted() async => await _channel.invokeMethod('isMuted') ?? false;

  static Future<void> bringToFront() async => await _channel.invokeMethod('bringToFront');

  static Future<void> startCallService() async => await _channel.invokeMethod('startCallService');

  static Future<void> stopCallService() async => await _channel.invokeMethod('stopCallService');

  static Future<bool> checkOverlayPermission() async => await _channel.invokeMethod('checkOverlayPermission') ?? false;

  static Future<void> requestOverlayPermission() async => await _channel.invokeMethod('requestOverlayPermission');
}
