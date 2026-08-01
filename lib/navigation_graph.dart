// Author: Ujwal N K
// Created: 2026, Mar 22

import 'package:flutter/material.dart';

enum CurrentPage {
  homePage,
  musicPage,
  callNavPage,
  callFavPage,
  callLogPage,
  callActPage,
  callAnsPage,
  volumePage,
  navigation,
}

class NavigationGraph extends ChangeNotifier {
  NavigationGraph._(); // private constructor

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
    _page = page;
    notifyListeners();
  }

  void pop() {
    if (!canPop) return;

    if (_page == CurrentPage.callFavPage || _page == CurrentPage.callLogPage) {
      _page = CurrentPage.callNavPage;
    } else {
      _page = CurrentPage.homePage;
    }

    data = {}; // Clear data on pop
    notifyListeners();
  }
}
