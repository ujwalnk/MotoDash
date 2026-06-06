// Author: Ujwal N K
// Created: 2026, Mar 22

import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:moto_dash/commons/dash_action.dart' show DashAction;
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

import '../navigation_graph.dart';
import '../service/native_bridge.dart';

Future<List<DashAction>> buildCallFavActions() async {
  final favorites = await _getFavorites();
  return [
    ...List.generate(
      favorites.length,
      (i) => DashAction(
        label: favorites.keys.elementAt(i),
        icons: [],
        action: () async {
          await CallBridge().startCallService();
          await FlutterPhoneDirectCaller.callNumber(favorites.values.elementAt(i));
          await Future.delayed(const Duration(milliseconds: 2000)); // TODO: Add this to configuration
          NavigationGraph.instance.goTo(CurrentPage.callActPage);
          await CallBridge().bringToFront();
        },
        canMask: false,
      ),
    ),
  ];
}

// TODO: Later change to store and retrieve a map rather than list
Future<Map<String, String>> _getFavorites() async {
  final prefs = await SharedPreferences.getInstance();

  final names = prefs.getStringList("fav_contact_names") ?? [];
  final numbers = prefs.getStringList("fav_contact_numbers") ?? [];
  return {for (var i = 0; i < names.length; i++) names[i]: numbers[i]};
}
