import 'package:flutter/services.dart';

class AssistantLauncher {
  static const MethodChannel _channel =
      MethodChannel('assistant.launcher');

  static Future<bool> launch() async {
    try {
      await _channel.invokeMethod('launchAssistant');
      return true;
    } catch (e) {
      return false;
    }
  }
}
