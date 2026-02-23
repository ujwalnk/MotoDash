import 'package:flutter/material.dart';

class DashAction {
  final String label;
  final List<IconData> icons;
  final VoidCallback action;

  DashAction({required this.label, required this.icons, required this.action});
}
