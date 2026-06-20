// Author: Ujwal N K

import 'package:flutter/material.dart';

/// Represents an dashboard item.
///
/// Encapsulates the display metadata and callback required to render and execute a dashboard action.
///
/// Side effects: None.
///
/// State mutations: None.
///
/// External variables modified: None.
class DashAction {
  final String label;
  final List<IconData> icons;
  final VoidCallback action;
  final bool canMask;

  DashAction({required this.label, required this.icons, required this.action, this.canMask = true});
}
