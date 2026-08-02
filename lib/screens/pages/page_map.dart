// Author: Ujwal N K
// Created:
// Page and Dash action mappings

import 'package:moto_dash/commons/dash_page.dart';
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

final Map<CurrentPage, DashPage> menuActions = {
  CurrentPage.callActPage: PageCallActive(),
  CurrentPage.callAnsPage: PageCallAnswer(),
  CurrentPage.callFavPage: PageCallFavourites(),
  CurrentPage.callLogPage: PageCallLog(),
  CurrentPage.callNavPage: PageCallNavigation(),
  CurrentPage.homePage: PageHome(),
  CurrentPage.musicPage: PageMusic(),
  CurrentPage.navigationPage: PageNavigation(),
  CurrentPage.volumePage: PageVolume(),
};
