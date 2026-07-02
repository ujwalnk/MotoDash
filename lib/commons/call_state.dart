// Author: Ujwal N K
// Created: 2026.06.29

import 'dart:async';

import 'package:moto_dash/bridges/telephony_bridge.dart';
import 'package:moto_dash/navigation_graph.dart';
import 'package:moto_dash/screens/pages/page_call_answer.dart' as page_call_answer;
import 'package:phone_state/phone_state.dart';

class CallStateListener {
  static late StreamSubscription _phoneStreamSubscription;
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;
    _phoneStreamSubscription = PhoneState.stream.listen((event) async {
      switch (event.status) {
        case PhoneStateStatus.CALL_INCOMING:
          if (NavigationGraph.instance.page != CurrentPage.callAnsPage) {
            NavigationGraph.instance.data = {
              page_call_answer.kDisplayValueKey: await TelephonyBridge.getContactName(event.number as String),
            };
            NavigationGraph.instance.goTo(CurrentPage.callAnsPage);
          }
          break;

        case PhoneStateStatus.CALL_STARTED:
        case PhoneStateStatus.CALL_OUTGOING:
          if (NavigationGraph.instance.page != CurrentPage.callActPage) {
            NavigationGraph.instance.goTo(CurrentPage.callActPage);
          }
          break;

        case PhoneStateStatus.CALL_ENDED:
          if (NavigationGraph.instance.page == CurrentPage.callActPage) {
            NavigationGraph.instance.goTo(CurrentPage.homePage);
          }
          break;

        default:
          break;
      }
    });
  }

  static void dispose() async {
    await _phoneStreamSubscription.cancel();
    _initialized = false;
  }
}
