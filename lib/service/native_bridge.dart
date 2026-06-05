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
}
