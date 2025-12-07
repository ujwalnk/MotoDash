import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:moto_dash/service/caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:moto_dash/commons/list_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallLogScreen extends StatefulWidget {
  const CallLogScreen({super.key});

  @override
  State<CallLogScreen> createState() => _CallLogScreenState();
}

class _CallLogScreenState extends State<CallLogScreen> {
  Color backgroundColor = Colors.black;
  Color fontColor = Colors.white;
  Color borderColor = Colors.white;

  bool showIcons = true;
  bool showLabel = true;

  double fontSize = 16.0;

  bool loading = true;
  List<CallLogEntry> lastCalls = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    backgroundColor = Color(prefs.getInt("background_color") ?? Colors.white.toARGB32());
    fontColor = Color(prefs.getInt("font_color") ?? Colors.white.toARGB32());
    borderColor = Color(prefs.getInt("option_border_color") ?? Colors.white.toARGB32());

    showIcons = prefs.getBool("call_show_icons") ?? true;
    showLabel = prefs.getBool("call_show_label") ?? true;

    fontSize = double.tryParse(prefs.getString("font_size") ?? "16.0") ?? 16.0;

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
        final number = entry.number ?? '';
        if (number.isNotEmpty && !uniqueMap.containsKey(number)) {
          uniqueMap[number] = entry;
        }
        if (uniqueMap.length == 5) break;
      }

      lastCalls = uniqueMap.values.toList();
    }
  }

  IconData _callIcon(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return Icons.call_received;
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.missed:
        return Icons.call_missed;
      default:
        return Icons.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();

    widgets.backgroundColor = backgroundColor;
    widgets.fontColor = fontColor;
    widgets.borderColor = borderColor;
    widgets.showIcons = showIcons;
    widgets.showLabel = showLabel;

    int itemCount = 6;

    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            for (var call in lastCalls)
              widgets.dashCardFunc(
                // Title: Contact name
                call.name ?? "Unknown",

                // Icon depends on call type
                _callIcon(call.callType),

                // On tap: Call number
                () async => await callNumber(call.number ?? ''),

                // Send context & count
                context,
                itemCount,

                // Subtitle: Phone number displayed beneath
                // subtitle: call.number ?? "Unknown",
              ),

            /// Back button
            widgets.dashCardFunc(
              'Return',
              Icons.undo,
              () => Navigator.pop(context),
              context,
              itemCount,
            ),
          ],
        ),
      ),
    );
  }
}
