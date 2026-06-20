// Author: Ujwal N K
// Created: 2026, Mar 22
// DashScreen - Call Log

import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart' show IconData;
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/dash_action.dart' show DashAction;
import 'package:permission_handler/permission_handler.dart';

import '../../navigation_graph.dart';
import '../../service/native_bridge.dart';

/// Builds dashboard actions from recent call log entries.
///
/// Retrieves recent call history using [_loadCallLogs] and creates a [DashAction] for each entry. Each action displays
/// the contact name or a formatted phone number, indicates the call type using [_callIcon], and initiates a direct call
/// when selected.
///
/// Side effects:
/// Reads call log data via [_loadCallLogs].
///
/// State mutations: None.
///
/// External variables modified: None.
///
/// Async behavior:
/// Returns a [Future] that completes with the generated list of [DashAction]
/// objects. The action callbacks perform asynchronous call and navigation
/// operations when invoked.
Future<List<DashAction>> buildCallLogActions() async {
  // Retrieve call logs from device
  final callLogs = await _loadCallLogs();

  return [
    // Generate the Call Logs as DashIcons
    ...List.generate(
      callLogs!.length,
      (i) => DashAction(
        // Add the name or format the number
        label: callLogs[i].name ?? _formatPhoneNumber(callLogs[i]),

        // Icon - missed / incoming / outgoing
        icons: [_callIcon(callLogs[i].callType)],

        // Place a call using the native caller application
        action: () async {
          // Start the Call Bridge service
          await CallBridge().startCallService();

          // Place the call & wait for the dialer to open
          await FlutterPhoneDirectCaller.callNumber(callLogs[i].number!);
          await Future.delayed(const Duration(milliseconds: 2000)); // TODO: Add this to configuration

          // Navigate to the active call management page
          NavigationGraph.instance.goTo(CurrentPage.callActPage);

          // Bring the applicaiton to the foreground
          await CallBridge().bringToFront();
        },

        canMask: false,
      ),
    ),
  ];
}

/// Loads recent call log entries from the device.
///
/// Requests phone permission, retrieves call history using [CallLog.query], sorts entries by descending timestamp, and
/// returns up to five unique contacts based on name or phone number.
///
/// Side effects:
/// Requests [Permission.phone] and reads device call log data using [CallLog.query].
///
/// State mutations: None.
///
/// External variables modified: None.
///
/// Async behavior:
/// Returns a [Future] that completes with a list of recent unique
/// [CallLogEntry] objects, or `null` if permission is not granted.
Future<List<CallLogEntry>?> _loadCallLogs() async {
  // Return null on missing permission
  if (!(await Permission.phone.request().isGranted)) {
    return null;
  }

  // Query the call log from the device
  Iterable<CallLogEntry> entries = await CallLog.query();
  final list = entries.toList();

  // Sort by time
  list.sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));

  final Map<String, CallLogEntry> uniqueMap = {};

  // List the most recent call logs based on user setting
  for (var entry in list) {
    final identifier = entry.name ?? entry.number ?? '';
    if (identifier.isNotEmpty && !uniqueMap.containsKey(identifier)) {
      uniqueMap[identifier] = entry;
    }
    if (uniqueMap.length == ConfigProvider.miscMaxCallLogsListed) break;
  }

  return uniqueMap.values.toList();
}

/// Formats the phone number associated with [call] for display.
///
/// Removes leading local or country prefixes and returns a normalized 10-digit representation when possible.
/// Returns `"Unknown"` if no phone number is available.
///
/// Side effects: None.
///
/// State mutations: None.
///
/// External variables modified: None.
String _formatPhoneNumber(CallLogEntry call) {
  if (call.number == null || call.number!.isEmpty) {
    return "Unknown";
  }

  // Remove the country identifier
  if (call.number![0] == "0") {
    return call.number!.substring(1, 10);
  } else {
    return call.number!.replaceFirst("+91", "").substring(0, 10);
  }
}

/// Maps a [CallType] to the corresponding dashboard icon.
///
/// Returns an icon representing incoming, outgoing, or missed calls. Defaults to [Icons.phone] when unsupported.
///
/// Side effects: None.
///
/// State mutations: None.
///
/// External variables modified: None.
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
