import 'dart:async';
import 'package:flutter/material.dart';

import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/split_screen_observer.dart';
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/service/global_services.dart';
import 'package:moto_dash/service/magent_intent_detector.dart';
import 'package:moto_dash/main.dart';

class CallLogScreen extends StatefulWidget {
  const CallLogScreen({super.key});

  @override
  State<CallLogScreen> createState() => _CallLogScreenState();
}

class _CallLogScreenState extends SplitScreenState<CallLogScreen>
    with RouteAware {
  bool showIcons = ConfigProvider.getShowIcons(Constants.kPathCallLog);
  bool showLabel = ConfigProvider.getShowLabel(Constants.kPathCallLog);

  bool loading = true;
  List<CallLogEntry> lastCalls = [];

  int selectedIndex = ConfigProvider.getEnableMagnetGestures ? 0 : -1;

  StreamSubscription<AppIntent>? _intentSub;
  late List<VoidCallback> _actions;

  // -----------------------------
  // RouteAware lifecycle
  // -----------------------------

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _unsubscribe();
    super.dispose();
  }

  @override
  void didPush() => _subscribe();

  @override
  void didPopNext() => _subscribe();

  @override
  void didPushNext() => _unsubscribe();

  void _subscribe() {
    _intentSub = magnetService.intents.listen(_handleIntent);
  }

  void _unsubscribe() {
    _intentSub?.cancel();
    _intentSub = null;
  }

  // -----------------------------

  @override
  void initState() {
    super.initState();
    _loadCallLogs();
  }

  Future<void> _loadCallLogs() async {
    if (await Permission.phone.request().isGranted) {
      Iterable<CallLogEntry> entries = await CallLog.query();
      final list = entries.toList();

      list.sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));

      final Map<String, CallLogEntry> uniqueMap = {};

      for (var entry in list) {
        final identifier = entry.name ?? entry.number ?? '';
        if (identifier.isNotEmpty && !uniqueMap.containsKey(identifier)) {
          uniqueMap[identifier] = entry;
        }
        if (uniqueMap.length == 5) break;
      }

      lastCalls = uniqueMap.values.toList();
    }

    loading = false;
    if (mounted) setState(() {});
  }

  IconData _callIcon(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return Icons.call_received_rounded;
      case CallType.outgoing:
        return Icons.call_made_rounded;
      case CallType.missed:
        return Icons.call_missed_rounded;
      default:
        return Icons.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();

    if (isSplitScreen) {
      widgets.showLabel = true;
      widgets.showIcons = false;
    } else {
      widgets.showIcons = showIcons;
      widgets.showLabel = showLabel;
    }

    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // -----------------------------
    // Prepare Visible Calls (DO NOT MUTATE ORIGINAL)
    // -----------------------------

    final visibleCalls = isSplitScreen ? lastCalls.take(3).toList() : lastCalls;

    // -----------------------------
    // Build Actions
    // -----------------------------

    _actions = [];

    for (var call in visibleCalls) {
      final number = call.number ?? '';
      _actions.add(() async {
        if (number.isNotEmpty) {
          await FlutterPhoneDirectCaller.callNumber(number);
        }
      });
    }

    // Return button
    _actions.add(() {
      Navigator.pop(context);
    });

    final int itemCount = _actions.length;

    if (selectedIndex >= itemCount) {
      selectedIndex = itemCount - 1;
    }

    return Scaffold(
      backgroundColor: ConfigProvider.getBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: widgets.dashView(isSplitScreen, [
          // -------------------------------
          // CALL ENTRIES
          // -------------------------------
          for (int i = 0; i < visibleCalls.length; i++)
            widgets.dashCardFunc(
              isSplitScreen
                  ? (visibleCalls[i].name?.substring(0, 10) ??
                        formatPhoneNumber(visibleCalls[i]))
                  : (visibleCalls[i].name ??
                        formatPhoneNumber(visibleCalls[i])),
              [_callIcon(visibleCalls[i].callType)],
              _actions[i],
              context,
              itemCount,
              isSelected: selectedIndex == i,
            ),

          // -------------------------------
          // RETURN BUTTON
          // -------------------------------
          widgets.dashCardFunc(
            'Return',
            [Icons.undo_rounded],
            _actions[itemCount - 1],
            context,
            itemCount,
            isSelected: selectedIndex == itemCount - 1,
            overrideShowIcons: isSplitScreen ? true : null,
          ),
        ]),
      ),
    );
  }

  void _handleIntent(AppIntent intent) {
    if (_actions.isEmpty) return;

    switch (intent) {
      case AppIntent.next:
        setState(() {
          selectedIndex = (selectedIndex + 1) % _actions.length;
        });
        break;

      case AppIntent.select:
        _actions[selectedIndex]();
        break;

      case AppIntent.back:
        Navigator.pop(context);
        break;
    }
  }

  String formatPhoneNumber(CallLogEntry call) {
    if (call.number == null || call.number!.isEmpty) {
      return "Unknown";
    }

    if (call.number![0] == "0") {
      return call.number!.substring(1, 10);
    } else {
      // TODO: Fix for all international numbers
      return call.number!.replaceFirst("+91", "").substring(0, 10);
    }
  }
}
