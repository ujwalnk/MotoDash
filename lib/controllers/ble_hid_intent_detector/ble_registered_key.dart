// Author: Ujwal N K /w ClaudeÎ
// Created: 2026.07.24
// A single registered button on a proprietary BLE peripheral, identified by the byte payload it
// sends in its notification. Mirrors HidRegisteredKey, but keys on a hex "code" string instead
// of an Android keyCode/scanCode pair, since a proprietary peripheral has no such concept.

import 'package:moto_dash/controllers/navigation_intent_handler.dart' show NavigationIntent;

class BleRegisteredKey {
  static const String fieldId = 'id';
  static const String fieldName = 'name';
  static const String fieldCode = 'code';
  static const String fieldSingleTap = 'singleTap';
  static const String fieldDoubleTap = 'doubleTap';
  static const String fieldTripleTap = 'tripleTap';

  /// UUID
  final String id;

  /// User-defined name for the button
  final String name;

  /// Hex string of the notification payload for this button, e.g. "01" or "0aff".
  /// Must match [BleHidBridge.payloadToCode] exactly - it's the join key between the live
  /// event stream and the registered buttons.
  final String code;

  final NavigationIntent? singleTap;
  final NavigationIntent? doubleTap;
  final NavigationIntent? tripleTap;

  const BleRegisteredKey({
    required this.id,
    required this.name,
    required this.code,
    this.singleTap,
    this.doubleTap,
    this.tripleTap,
  });

  factory BleRegisteredKey.fromJson(Map<String, dynamic> json) {
    return BleRegisteredKey(
      id: json[fieldId] as String,
      name: json[fieldName] as String,
      code: json[fieldCode] as String,
      singleTap: _intentFromName(json[fieldSingleTap] as String?),
      doubleTap: _intentFromName(json[fieldDoubleTap] as String?),
      tripleTap: _intentFromName(json[fieldTripleTap] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      fieldId: id,
      fieldName: name,
      fieldCode: code,
      fieldSingleTap: singleTap?.name,
      fieldDoubleTap: doubleTap?.name,
      fieldTripleTap: tripleTap?.name,
    };
  }

  static const Object _unset = Object();

  BleRegisteredKey copyWith({
    String? id,
    String? name,
    String? code,
    Object? singleTap = _unset,
    Object? doubleTap = _unset,
    Object? tripleTap = _unset,
  }) {
    return BleRegisteredKey(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      singleTap: identical(singleTap, _unset) ? this.singleTap : singleTap as NavigationIntent?,
      doubleTap: identical(doubleTap, _unset) ? this.doubleTap : doubleTap as NavigationIntent?,
      tripleTap: identical(tripleTap, _unset) ? this.tripleTap : tripleTap as NavigationIntent?,
    );
  }

  static NavigationIntent? _intentFromName(String? name) {
    if (name == null) return null;
    return NavigationIntent.values.firstWhere((intent) => intent.name == name);
  }
}
