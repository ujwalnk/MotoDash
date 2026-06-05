import 'package:flutter/material.dart';
import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/navigation_graph.dart';
import 'package:moto_dash/service/native_bridge.dart' show AssistantBridge;
import 'package:phone_state/phone_state.dart';

Future<List<DashAction>> buildHomeActions() async {
  return [
    DashAction(
      label: 'Phone',
      icons: [Icons.phone_rounded],
      action: () {
        PhoneState.stream.listen((state) {
          if (state.status == PhoneStateStatus.CALL_STARTED) {
            NavigationGraph.instance.goTo(CurrentPage.callActPage);
          } else {
            NavigationGraph.instance.goTo(CurrentPage.callNavPage);
          }
        });
      },
    ),
    DashAction(
      label: 'Music',
      icons: [Icons.music_note_rounded],
      action: () => NavigationGraph.instance.goTo(CurrentPage.musicPage),
    ),
    DashAction(label: 'Assistant', icons: [Icons.assistant_rounded], action: () => AssistantBridge.launch()),
    DashAction(
      label: 'Volume',
      icons: [Icons.volume_up_rounded],
      action: () => NavigationGraph.instance.goTo(CurrentPage.volumePage),
    ),
  ];
}
