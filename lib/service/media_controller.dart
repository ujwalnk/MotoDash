import 'package:flutter/services.dart';

class MediaSessionController {
  static const MethodChannel _channel =
      MethodChannel('media_session_control');

  static Future<void> toggle() async {
    await _channel.invokeMethod('toggle');
  }
}
