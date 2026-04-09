// Author: Ujwal N K
// Created: 2026, Mar 22

import 'package:flutter/material.dart';

enum CurrentPage {
  homePage,
  musicPage,
  callNavPage,
  callFavPage,
  callLogPage,
  volumePage,
}

class NavigationGraph extends ChangeNotifier {
  NavigationGraph._();

  static final NavigationGraph instance = NavigationGraph._();

  // Currently Active Page
  CurrentPage _page = CurrentPage.homePage;

  // Getter for current page
  CurrentPage get page => _page;

  // Getter - can pop?
  bool get canPop => _page != CurrentPage.homePage;

  // Full navigation with logic — used by the service isolate only.
  Future<void> goTo(CurrentPage page) async {
    debugPrint("Current Page: $_page -> $page");
    _page = page;
    notifyListeners();
  }

  void pop() {
    debugPrint("At pop");
    if (!canPop) {
      debugPrint("Unable to Pop");
      return;
    }
    if (_page == CurrentPage.callFavPage || _page == CurrentPage.callLogPage) {
      _page = CurrentPage.callNavPage;
      debugPrint("Going back to callNav");
    } else {
      _page = CurrentPage.homePage;
      debugPrint("Going back to home");
    }
    debugPrint("Popped!");
    notifyListeners();
  }

  // Dumb mirror — used by the main isolate only.
  // Reflects whatever page the service isolate reports via IPC.
  // No navigation logic runs here; this is purely a display sync.
  void syncPage(CurrentPage page) {
    if (_page == page) return;
    debugPrint("[main] syncPage: $_page -> $page");
    _page = page;
    notifyListeners();
  }
}