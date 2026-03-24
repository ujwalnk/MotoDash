import 'package:flutter/material.dart';
import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/navigation_graph.dart';
import 'package:moto_dash/service/assistant_launcher.dart'
    show AssistantLauncher;

Future<List<DashAction>> buildHomeActions() async {
  return [
    DashAction(
      label: 'Phone',
      icons: [Icons.phone_rounded],
      action: () => NavigationGraph.instance.goTo(CurrentPage.callNavPage),
    ),
    DashAction(
      label: 'Music',
      icons: [Icons.music_note_rounded],
      action: () => NavigationGraph.instance.goTo(CurrentPage.musicPage),
      // Navigator.pushNamed(context, Constants.kPathMusic),
    ),
    DashAction(
      label: 'Assistant',
      icons: [Icons.assistant_rounded],
      action: () => AssistantLauncher.launch(),
    ),
    DashAction(
      label: 'Volume',
      icons: [Icons.volume_up_rounded],
      action: () => NavigationGraph.instance.goTo(CurrentPage.volumePage),
      // () => Navigator.pushNamed(context, Constants.kPathVolume),
    ),
  ];
}
