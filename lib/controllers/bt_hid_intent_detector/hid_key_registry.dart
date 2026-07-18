// Author: Ujwal N K
// Created: 2026.07.12

import 'package:moto_dash/controllers/navigation_intent_handler.dart' show NavigationIntent;

class HidRegisteredKey {
  static const String fieldId = 'id';
  static const String fieldName = 'name';
  static const String fieldKeyCode = 'keyCode';
  static const String fieldScanCode = 'scanCode';
  static const String fieldSingleTap = 'singleTap';
  static const String fieldDoubleTap = 'doubleTap';
  static const String fieldTripleTap = 'tripleTap';

  /// UUID
  final String id;

  /// User-defined name for the button
  final String name;

  /// Android keyCode
  final int keyCode;

  /// Optional scanCode
  final int? scanCode;

  /// Action for each gesture
  final NavigationIntent? singleTap;
  final NavigationIntent? doubleTap;
  final NavigationIntent? tripleTap;

  const HidRegisteredKey({
    required this.id,
    required this.name,
    required this.keyCode,
    this.scanCode,
    this.singleTap,
    this.doubleTap,
    this.tripleTap,
  });

  factory HidRegisteredKey.fromJson(Map<String, dynamic> json) {
    return HidRegisteredKey(
      id: json[fieldId] as String,
      name: json[fieldName] as String,
      keyCode: json[fieldKeyCode] as int,
      scanCode: json[fieldScanCode] as int?,
      singleTap: _intentFromName(json[fieldSingleTap] as String?),
      doubleTap: _intentFromName(json[fieldDoubleTap] as String?),
      tripleTap: _intentFromName(json[fieldTripleTap] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      fieldId: id,
      fieldName: name,
      fieldKeyCode: keyCode,
      fieldScanCode: scanCode,
      fieldSingleTap: singleTap?.name,
      fieldDoubleTap: doubleTap?.name,
      fieldTripleTap: tripleTap?.name,
    };
  }

  /// Sentinel used by [copyWith] to distinguish "field not passed" from "field explicitly set to null",
  /// since the gesture fields are nullable (a gesture can be unassigned).
  static const Object _unset = Object();

  HidRegisteredKey copyWith({
    String? id,
    String? name,
    int? keyCode,
    Object? scanCode = _unset,
    Object? singleTap = _unset,
    Object? doubleTap = _unset,
    Object? tripleTap = _unset,
  }) {
    return HidRegisteredKey(
      id: id ?? this.id,
      name: name ?? this.name,
      keyCode: keyCode ?? this.keyCode,
      scanCode: identical(scanCode, _unset) ? this.scanCode : scanCode as int?,
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
