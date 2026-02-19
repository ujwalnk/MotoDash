import 'package:flutter/material.dart';

import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart'
    show FlutterPhoneDirectCaller;

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/split_screen_observer.dart';
import 'package:moto_dash/commons/list_builder.dart';

class CallLogScreen extends StatefulWidget {
  const CallLogScreen({super.key});

  @override
  State<CallLogScreen> createState() => _CallLogScreenState();
}

class _CallLogScreenState extends SplitScreenState<CallLogScreen> {
  Color backgroundColor = ConfigProvider.getBackgroundColor;
  Color fontColor = ConfigProvider.getFontColor;
  Color borderColor = ConfigProvider.getOptionBorderColor;

  bool showIcons = ConfigProvider.getShowIcons(Constants.kPathCallLog);
  bool showLabel = ConfigProvider.getShowLabel(Constants.kPathCallLog);

  double fontSize = ConfigProvider.getFontSize;

  bool loading = true;
  List<CallLogEntry> lastCalls = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _loadCallLogs();

    loading = false;
    setState(() {});
  }

  Future<void> _loadCallLogs() async {
    if (await Permission.phone.request().isGranted) {
      Iterable<CallLogEntry> entries = await CallLog.query();

      final list = entries.toList();

      // Sort by timestamp DESC
      list.sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));

      // Keep only unique phone numbers
      final Map<String, CallLogEntry> uniqueMap = {};

      for (var entry in list) {
        final identifier = entry.name ?? entry.number ?? '';
        if (identifier.isNotEmpty && !uniqueMap.containsKey(identifier)) {
          uniqueMap[identifier] = entry;
          debugPrint("Adding to unique list: $identifier");
        }
        if (uniqueMap.length == 5) break;
      }

      lastCalls = uniqueMap.values.toList();
    }
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

    int itemCount = 6;

    widgets.backgroundColor = backgroundColor;
    widgets.fontColor = fontColor;
    widgets.borderColor = borderColor;
    if (isSplitScreen) {
      widgets.showLabel = true;
      widgets.showIcons = false;
      itemCount = 4;

      itemCount = 3;
      lastCalls = lastCalls.take(3).toList();
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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
        child: widgets.dashView(isSplitScreen, [
          for (var call in lastCalls)
            widgets.dashCardFunc(
              // Title: Contact name
              isSplitScreen
                  ? call.name?.substring(0, 10) ?? formatPhoneNumber(call)
                  : (call.name ?? formatPhoneNumber(call)),

              // Icon depends on call type
              [_callIcon(call.callType)],

              // On tap: Call number
              () async =>
                  await FlutterPhoneDirectCaller.callNumber(call.number ?? ''),

              // Send context & count
              context,
              itemCount,
            ),

          /// Back button
          widgets.dashCardFunc(
            'Return',
            [Icons.undo_rounded],
            () => Navigator.pop(context),
            context,
            itemCount,
            overrideShowIcons: isSplitScreen ? isSplitScreen : null,
          ),
        ]),
      ),
    );
  }

  String formatPhoneNumber(CallLogEntry call) {
    if (call.number!.isEmpty) {
      return "Unknown";
    }
    if (call.number![0] == "0") {
      return call.number!.substring(1, 10);
    } else {
      // TODO: Fix later for all international numbers
      return call.number!.replaceFirst("+91", "").substring(0, 10);
    }
  }
}
