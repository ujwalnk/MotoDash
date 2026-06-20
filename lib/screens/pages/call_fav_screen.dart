// Author: Ujwal N K
// Created: 2026, Mar 22
// DashScreen - Favourite contacts

import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:moto_dash/commons/dash_action.dart' show DashAction;
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

import '../../navigation_graph.dart';
import '../../service/native_bridge.dart';

/// Builds dashboard actions for configured favorite contacts.
///
/// Retrieves favorite contacts using [_getFavorites] and creates a [DashAction] for each entry. When invoked, an action
/// starts the call service, places a call to the associated contact, navigates to [CurrentPage.callActPage] through
/// [NavigationGraph.instance], and brings the application to the foreground using [CallBridge.bringToFront].
///
/// Side effects:
/// Reads persisted favorite contact data via [_getFavorites].
///
/// State mutations: None.
///
/// External variables modified: None.
///
/// Async behavior:
/// Returns a [Future] that completes with the generated list of [DashAction] objects. The action callbacks perform
/// asynchronous call and navigation operations when invoked.
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

/// Retrieves the configured favorite contacts.
///
/// Reads contact names and phone numbers from [SharedPreferences] and returns them as a map where the key is the
/// contact name and the value is the phone number.
///
/// Side effects:
/// Reads persisted data from [SharedPreferences].
///
/// State mutations: None.
///
/// External variables modified: None.
///
/// Async behavior:
/// Returns a [Future] that completes after obtaining the
/// [SharedPreferences] instance and loading the stored contact data.
Future<Map<String, String>> _getFavorites() async {
  // TODO: Later change to store and retrieve a map rather than list
  final prefs = await SharedPreferences.getInstance();

  final names = prefs.getStringList("fav_contact_names") ?? [];
  final numbers = prefs.getStringList("fav_contact_numbers") ?? [];
  return {for (var i = 0; i < names.length; i++) names[i]: numbers[i]};
}
