import 'package:flutter/material.dart';
import 'package:moto_dash/commons/list_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color backgroundColor = Colors.black;
  Color fontColor = Colors.white;
  Color borderColor = Colors.white;

  bool showIcons = true;
  bool showLabel = true;

  double fontSize = 16.0;

  bool loading = true;

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

    showIcons = prefs.getBool("home_show_icons") ?? true;
    showLabel = prefs.getBool("home_show_label") ?? true;

    fontSize = double.tryParse(prefs.getString("font_size") ?? "16.0") ?? 16.0;

    loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();
    int itemCount = 5;

    // Set Widget properties
    widgets.backgroundColor = backgroundColor;
    widgets.fontColor = fontColor;
    widgets.borderColor = borderColor;
    widgets.showIcons = showIcons;
    widgets.showLabel = showLabel;

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            widgets.dashCardRoute(
              'Phone',
              Icons.phone,
              '/phone',
              context,
              itemCount,
            ),
            widgets.dashCardRoute(
              'Music',
              Icons.music_note,
              '/music',
              context,
              itemCount,
            ),
            widgets.dashCardRoute(
              'Voice Note',
              Icons.mic,
              '/voicenote',
              context,
              itemCount,
            ),
            widgets.dashCardRoute(
              'Maps',
              Icons.map,
              '/maps',
              context,
              itemCount,
            ),
            widgets.dashCardRoute(
              'Volume',
              Icons.volume_up,
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
}
