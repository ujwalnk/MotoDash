import 'package:flutter/material.dart';

class DashAction {
  final String label;
  final List<IconData> icons;
  final VoidCallback action;

  /// Set to true for actions that need an Android Activity context —
  /// phone calls, assistant launch, or any intent that opens another app.
  /// The service isolate will proxy these to the main isolate via IPC
  /// (and foreground the app) instead of executing them directly.
  /// Defaults to false — pure Dart and most platform-channel actions
  /// (volume, media) work fine from the service isolate.
  final bool requiresActivity;

  DashAction({
    required this.label,
    required this.icons,
    required this.action,
    this.requiresActivity = false,
  });
}