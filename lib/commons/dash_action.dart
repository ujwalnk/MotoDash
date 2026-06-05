import 'package:flutter/material.dart';

class DashAction {
  final String label;
  final List<IconData> icons;
  final VoidCallback action;
  final bool canMask;

  DashAction({required this.label, required this.icons, required this.action, this.canMask = true});
}
