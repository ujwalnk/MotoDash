// Author: Ujwal N K
// Created: 2026, Mar 22

import 'package:flutter/material.dart';
import 'package:moto_dash/screens/pages/page_map.dart';

enum CurrentPage {
  homePage,
  musicPage,
  callNavPage,
  callFavPage,
  callLogPage,
  callActPage,
  callAnsPage,
  volumePage,
  navigationPage,
}

class NavigationGraph extends ChangeNotifier {
  NavigationGraph._() {
    menuActions[_page]?.init();
    menuActions[_page]?.onRefreshRequired = notifyListeners;
  } // private constructor

  static final NavigationGraph instance = NavigationGraph._();

  // Currently Active Page
  CurrentPage _page = CurrentPage.homePage;

  // Getter for current page
  CurrentPage get page => _page;

  // Getter - can pop?
  bool get canPop => _page != CurrentPage.homePage && _page != CurrentPage.callActPage;

  // Data
  Map<String, dynamic> data = {};

  Future<void> goTo(CurrentPage page) async {
    // TODO: Check for guard required against navigating to the same page

    menuActions[_page]?.onRefreshRequired = null;
    await menuActions[_page]?.terminate(); // Terminate the previous page

    _page = page;

    menuActions[_page]?.onRefreshRequired = notifyListeners;
    await menuActions[_page]?.init(); // Initialize the new page

    notifyListeners();
  }

  Future<void> pop() async {
    if (!canPop) return;

    menuActions[_page]?.onRefreshRequired = null;
    await menuActions[_page]?.terminate();

    if (_page == CurrentPage.callFavPage || _page == CurrentPage.callLogPage) {
      await goTo(CurrentPage.callNavPage);
    } else {
      await goTo(CurrentPage.homePage);
    }

    data = {}; // Clear data on pop
  }
}
