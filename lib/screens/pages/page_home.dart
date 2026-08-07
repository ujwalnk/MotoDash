// Author: Ujwal N K
// Created:
// DashScreen - Home screen

import 'package:flutter/material.dart';
import 'package:moto_dash/bridges/assistant_bridge.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/commons/dash_page.dart';
import 'package:moto_dash/commons/permission_check.dart';
import 'package:moto_dash/navigation_graph.dart';

class PageHome extends DashPage {
  bool _callPlacePermission = false;
  bool _callLogPermission = false;
  bool _callFavContactsNotNull = false;
  bool _voiceNotePermission = false;

  @override
  Future<void> init() async {
    _callPlacePermission = await PermissionCheck.phone;
    _callLogPermission = await PermissionCheck.callLog();
    _callFavContactsNotNull = ConfigProvider.phoneFavContactNames.isNotEmpty;
    _voiceNotePermission = await PermissionCheck.hasVoiceNotePermissions();
  }

  @override
  Future<List<DashAction>> buildActions() async {
    return [
      if (_callPlacePermission && (_callLogPermission || _callFavContactsNotNull))
        DashAction(
          label: 'Phone',
          icons: [Icons.phone_rounded],
          action: () => NavigationGraph.instance.goTo(CurrentPage.callNavPage),
        ),
      DashNavigation(
        label: 'Music',
        icons: [Icons.music_note_rounded],
        action: () => NavigationGraph.instance.goTo(CurrentPage.musicPage),
      ),
      DashNavigation(
        label: "Navigation",
        icons: [Icons.navigation_rounded],
        action: () => NavigationGraph.instance.goTo(CurrentPage.navigationPage),
      ),
      DashAction(label: 'Assistant', icons: [Icons.assistant_rounded], action: () => AssistantBridge.launch()),
      // Only shown once mic + storage permissions are granted — never a
      // disabled tile, it simply doesn't exist until then. Re-evaluated
      // every time this page is (re)initialized, i.e. every time the user
      // navigates to or back to Home.
      if (_voiceNotePermission)
        DashNavigation(
          label: 'Voice Note',
          icons: [Icons.mic_rounded],
          action: () => NavigationGraph.instance.goTo(CurrentPage.voiceNotePage),
        ),
      DashNavigation(
        label: 'Volume',
        icons: [Icons.volume_up_rounded],
        action: () => NavigationGraph.instance.goTo(CurrentPage.volumePage),
      ),
    ];
  }
}
