// Author: Ujwal N K
// Created: 2026, Mar 22

import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart' show IconData;
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:moto_dash/commons/dash_action.dart' show DashAction;
import 'package:permission_handler/permission_handler.dart';

Future<List<DashAction>> buildCallLogActions() async {
  final callLogs = await _loadCallLogs();

  return [
    ...List.generate(
      callLogs!.length,
      (i) => DashAction(
        label: callLogs[i].name ?? _formatPhoneNumber(callLogs[i]),
        icons: [_callIcon(callLogs[i].callType)],
        // Direct phone calls require an Activity Intent and cannot be
        // executed from the service isolate.
        requiresActivity: true,
        action: () async {
          await FlutterPhoneDirectCaller.callNumber(callLogs[i].number!);
        },
      ),
    )
  ];
}

Future<List<CallLogEntry>?> _loadCallLogs() async {
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

    return uniqueMap.values.toList();
  }
  return null;
}

String _formatPhoneNumber(CallLogEntry call) {
  if (call.number == null || call.number!.isEmpty) {
    return "Unknown";
  }

  if (call.number![0] == "0") {
    return call.number!.substring(1, 10);
  } else {
    return call.number!.replaceFirst("+91", "").substring(0, 10);
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