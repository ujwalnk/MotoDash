// Author: Ujwal N K
// Created: 2026.07.29

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/dash_action.dart';

abstract class DashPage {
  Future<void> init() async {}

  VoidCallback? onRefreshRequired;
  void refresh() => onRefreshRequired?.call();

  Future<List<DashAction>> buildActions();

  Future<void> terminate() async {}
}
