// Author: Ujwal N K
// Created: 2026, Mar 22

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/dash_action.dart';

enum CurrentPage {
  homePage,
  musicPage,
  callNavPage,
  callFavPage,
  callLogPage,
  volumePage,
}

class NavigationGraph extends ChangeNotifier {
  NavigationGraph._(); // private constructor

  static final NavigationGraph instance = NavigationGraph._();

  // Currently Active Page
  CurrentPage _page = CurrentPage.homePage;

  // Getter for current page
  CurrentPage get page => _page;

  // Getter - can pop?
  bool get canPop => _page != CurrentPage.homePage;

  Future<void> goTo(CurrentPage page) async {
    debugPrint("Current Page: $_page -> $page");
    _page = page;
    notifyListeners();
  }

  static final dashActionReturn = DashAction(
    label: 'Return',
    icons: [Icons.undo_rounded],
    action: () {
      // TODO: Implement Back Funcationality here
    },
  );

  void pop() {
    if (!canPop) return;
    if (_page == CurrentPage.callFavPage || _page == CurrentPage.callLogPage) {
      _page = CurrentPage.callNavPage;
    } else {
      _page = CurrentPage.homePage;
    }
    notifyListeners();
  }
}
