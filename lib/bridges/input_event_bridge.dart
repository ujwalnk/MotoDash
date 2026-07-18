// Author: Ujwal N K
// Created: 2026.07.12

import 'dart:async';

import 'package:flutter/services.dart';

class InputEventBridge {
  static const EventChannel _channel = EventChannel('in.madilu.motodash/input_events');

  static Stream<Map<dynamic, dynamic>> get events => _channel.receiveBroadcastStream().cast<Map<dynamic, dynamic>>();
}
