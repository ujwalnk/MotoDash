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
  NavigationGraph._(); // private constructor

  static final NavigationGraph instance = NavigationGraph._();

  // Currently Active Page
  CurrentPage _page = CurrentPage.homePage;

  CurrentPage get page => _page;

  bool get canPop => _page != CurrentPage.homePage && _page != CurrentPage.callActPage;

  Future<void>? _readyFuture;

  // Data
  Map<String, dynamic> data = {};

  /// Call this once, before the root screen is shown / before anything
  /// reads `menuActions[_page]` for the home page. Safe to call multiple
  /// times — subsequent calls just await the same in-flight/completed Future.
  Future<void> ensureInitialized() {
    return _readyFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    menuActions[_page]?.onRefreshRequired = notifyListeners;
    await menuActions[_page]?.init(); // <-- home page's async init awaited here
    notifyListeners();
  }

  Future<void> goTo(CurrentPage page) async {
    await ensureInitialized();

    if (_page == page) return;

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
