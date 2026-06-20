// Author: Ujwal N K
// Created:
// Page and Dash action mappings

import 'package:moto_dash/commons/dash_action.dart';
import 'package:moto_dash/navigation_graph.dart';
import 'package:moto_dash/screens/pages/call_act_screen.dart';
import 'package:moto_dash/screens/pages/call_fav_screen.dart';
import 'package:moto_dash/screens/pages/call_log_screen.dart';
import 'package:moto_dash/screens/pages/call_nav_screen.dart';
import 'package:moto_dash/screens/pages/home_screen.dart';
import 'package:moto_dash/screens/pages/music_screen.dart';
import 'package:moto_dash/screens/pages/volume_screen.dart';

final Map<CurrentPage, Future<List<DashAction>> Function()> menuActions = {
  CurrentPage.homePage: buildHomeActions,
  CurrentPage.musicPage: buildMusicActions,
  CurrentPage.volumePage: buildVolumeActions,
  CurrentPage.callNavPage: buildCallNavActions,
  CurrentPage.callFavPage: buildCallFavActions,
  CurrentPage.callLogPage: buildCallLogActions,
  CurrentPage.callActPage: buildCallActiveActions,
};
