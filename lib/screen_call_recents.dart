import 'dart:async';
import 'package:flutter/material.dart';

import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/dash_action.dart';
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

  List<DashAction> _items = [];
  bool _didAutoSpeak = false;

  // ------------------------------------------------
  // RouteAware
  // ------------------------------------------------

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
  void didPushNext() => _unsubscribe();

  @override
  void didPopNext() {
    _subscribe();
    _didAutoSpeak = false;
    _maybeSpeakFirst();
  }

  void _subscribe() {
    _intentSub = magnetService.intents.listen(_handleIntent);
  }

  void _unsubscribe() {
    _intentSub?.cancel();
    _intentSub = null;
  }

  // ------------------------------------------------
  // INIT
  // ------------------------------------------------

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

  // ------------------------------------------------
  // BUILD
  // ------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final DashWidgets widgets = DashWidgets();

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

    final visibleCalls = isSplitScreen ? lastCalls.take(3).toList() : lastCalls;

    _items = [];

    for (var call in visibleCalls) {
      final number = call.number ?? '';

      final label = isSplitScreen
          ? (call.name?.substring(
                  0,
                  call.name!.length > 10 ? 10 : call.name!.length,
                ) ??
                formatPhoneNumber(call))
          : (call.name ?? formatPhoneNumber(call));

      _items.add(
        DashAction(
          label: label,
          icons: [_callIcon(call.callType)],
          action: () async {
            if (number.isNotEmpty) {
              await FlutterPhoneDirectCaller.callNumber(number);
            }
          },
        ),
      );
    }

    _items.add(
      DashAction(
        label: 'Return',
        icons: [Icons.undo_rounded],
        action: () => Navigator.pop(context),
      ),
    );

    if (selectedIndex >= _items.length) {
      selectedIndex = _items.length - 1;
    }

    _maybeSpeakFirst();

    return Scaffold(
      backgroundColor: ConfigProvider.getBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: widgets.dashView(
          isSplitScreen,
          List.generate(_items.length, (index) {
            return widgets.dashCardAction(
              _items[index],
              context,
              _items.length,
              isSelected: selectedIndex == index,
            );
          }),
        ),
      ),
    );
  }

  // ------------------------------------------------
  // Magnet Handler
  // ------------------------------------------------

  void _handleIntent(AppIntent intent) {
    if (_items.isEmpty || selectedIndex == -1) return;

    switch (intent) {
      case AppIntent.next:
        setState(() {
          selectedIndex = (selectedIndex + 1) % _items.length;
        });

        ttsService.speak(_items[selectedIndex].label);
        break;

      case AppIntent.select:
        _items[selectedIndex].action();
        break;

      case AppIntent.back:
        Navigator.pop(context);
        break;
    }
  }

  // ------------------------------------------------
  // Auto speak only if last nav was magnet
  // ------------------------------------------------

  void _maybeSpeakFirst() {
    if (lastNavigationWasMagnet &&
        !_didAutoSpeak &&
        selectedIndex != -1 &&
        _items.isNotEmpty) {
      _didAutoSpeak = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() => selectedIndex = 0);
        ttsService.speak(_items[0].label);

        lastNavigationWasMagnet = false;
      });
    }
  }

  // ------------------------------------------------
  // Helpers
  // ------------------------------------------------

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

  String formatPhoneNumber(CallLogEntry call) {
    if (call.number == null || call.number!.isEmpty) {
      return "Unknown";
    }

    if (call.number![0] == "0") {
      return call.number!.substring(1, 10);
    } else {
      return call.number!.replaceFirst("+91", "").substring(0, 10);
    }
  }
}
