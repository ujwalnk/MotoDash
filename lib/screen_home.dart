import 'package:flutter/material.dart';
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/commons/split_screen_observer.dart';
import 'package:moto_dash/service/assistant_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends SplitScreenState<HomeScreen> {
  Color backgroundColor = Colors.black;
  Color fontColor = Colors.white;
  Color borderColor = Colors.white;

  bool showIcons = true;
  bool showLabel = true;
  bool loading = true;
  bool showVolumeTip = true;
  bool hasFavContacts = false;

  double fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    backgroundColor = Color(
      prefs.getInt("background_color") ?? Colors.black.toARGB32(),
    );
    fontColor = Color(prefs.getInt("font_color") ?? Colors.white.toARGB32());
    borderColor = Color(
      prefs.getInt("option_border_color") ?? Colors.white.toARGB32(),
    );

    showIcons = prefs.getBool("home_show_icons") ?? true;
    showLabel = prefs.getBool("home_show_label") ?? true;

    fontSize = double.tryParse(prefs.getString("font_size") ?? "16.0") ?? 16.0;

    showVolumeTip = prefs.getBool("show_volume_tip") ?? true;
    hasFavContacts =
        prefs.getStringList("fav_contact_names")?.toList().isNotEmpty ?? false;
    debugPrint(
      "hasFavContacts: ${prefs.getStringList("fav_contact_names")}, ${hasFavContacts}",
    );

    loading = false;
    setState(() {});

    // Show popup after UI builds
    if (showVolumeTip) {
      Future.delayed(Duration(milliseconds: 300), _showVolumeTipDialog);
    }
  }

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();
    int itemCount = 4;

    // Set Widget properties
    widgets.backgroundColor = backgroundColor;
    widgets.fontColor = fontColor;
    widgets.borderColor = borderColor;
    if (isSplitScreen) {
      widgets.showLabel = false;
      widgets.showIcons = true;
    } else {
      widgets.showIcons = showIcons;
      widgets.showLabel = showLabel;
    }
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    debugPrint("hasFavContacts: $hasFavContacts");

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
        // child: ListView(
        child: widgets.dashView(
          // padding: const EdgeInsets.all(10),
          isSplitScreen,
          [
            widgets.dashCardRoute(
              'Phone',
              [Icons.phone_rounded],
              isSplitScreen
                  ? (!hasFavContacts ? "/phone_log" : "/phone_nav")
                  : (hasFavContacts ? '/phone_fav' : '/phone_log'),
              context,
              itemCount,
            ),
            widgets.dashCardRoute(
              'Music',
              [Icons.music_note_rounded],
              '/music',
              context,
              itemCount,
            ),
            // widgets.dashCardRoute(
            //   'Voice Note',
            //   [Icons.mic_rounded],
            //   '/voicenote',
            //   context,
            //   itemCount,
            // ),
            widgets.dashCardFunc(
              'Assistant',
              [Icons.assistant_rounded],
              () {
                AssistantLauncher.launch();
              },
              context,
              itemCount,
            ),
            widgets.dashCardRoute(
              'Volume',
              [Icons.volume_up_rounded],
              '/volume',
              context,
              itemCount,
              routeOnLongTap: "/settings",
            ),
          ],
        ),
      ),
    );
  }

  void _showVolumeTipDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Tip"),
        content: const Text(
          "Double tap the Volume button on screen to open the Settings page.",
        ),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text("Never show again"),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool("show_volume_tip", false);
              showVolumeTip = false;
              if (mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
