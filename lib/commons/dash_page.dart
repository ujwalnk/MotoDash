// Author: Ujwal N K
// Created: 2026.07.29

import 'package:moto_dash/commons/dash_action.dart';

abstract class DashPage {
  Future<void> init() async {}

  Future<void> terminate() async {}

  Future<List<DashAction>> buildActions();
}
