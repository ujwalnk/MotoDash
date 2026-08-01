// Author: Ujwal N K
// Created:
// Page and Dash action mappings

import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/navigation_graph.dart';
import 'package:moto_dash/screens/pages/page_call_active.dart';
import 'package:moto_dash/screens/pages/page_call_answer.dart';
import 'package:moto_dash/screens/pages/page_call_favourites.dart';
import 'package:moto_dash/screens/pages/page_call_log.dart';
import 'package:moto_dash/screens/pages/page_call_navigation.dart';
import 'package:moto_dash/screens/pages/page_home.dart';
import 'package:moto_dash/screens/pages/page_music.dart';
import 'package:moto_dash/screens/pages/page_navigation.dart';
import 'package:moto_dash/screens/pages/page_volume.dart';

// final Map<CurrentPage, Future<List<DashAction>> Function()> menuActions = {
//   CurrentPage.callActPage: buildCallActiveActions,
//   CurrentPage.callAnsPage: buildCallAnswerActions,
//   CurrentPage.callFavPage: buildCallFavActions,
//   CurrentPage.callLogPage: buildCallLogActions,
//   CurrentPage.callNavPage: buildCallNavActions,
//   CurrentPage.homePage: buildHomeActions,
//   CurrentPage.musicPage: buildMusicActions,
//   CurrentPage.navigation: buildNavigationActions,
//   CurrentPage.volumePage: buildVolumeActions,
// };

final Map<CurrentPage, Future<List<DashAction>> Function()> menuActions = {
  CurrentPage.callActPage: buildCallActiveActions,
  CurrentPage.callAnsPage: buildCallAnswerActions,
  CurrentPage.callFavPage: buildCallFavActions,
  CurrentPage.callLogPage: buildCallLogActions,
  CurrentPage.callNavPage: buildCallNavActions,
  CurrentPage.homePage: buildHomeActions,
  CurrentPage.musicPage: buildMusicActions,
  CurrentPage.navigation: buildNavigationActions,
  CurrentPage.volumePage: buildVolumeActions,
};
