import 'package:flutter/material.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/service/media_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
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
    backgroundColor = Color(
      prefs.getInt("background_color") ?? Colors.white.toARGB32(),
    );
    fontColor = Color(prefs.getInt("font_color") ?? Colors.white.toARGB32());
    borderColor = Color(
      prefs.getInt("option_border_color") ?? Colors.white.toARGB32(),
    );

    showIcons = prefs.getBool("music_show_icons") ?? true;
    showLabel = prefs.getBool("music_show_label") ?? true;

    fontSize = double.tryParse(prefs.getString("font_size") ?? "16.0") ?? 16.0;

    loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();
    int itemCount = 4;

    // Set Widget properties
    widgets.backgroundColor = backgroundColor;
    widgets.fontColor = fontColor;
    widgets.borderColor = borderColor;
    widgets.showIcons = showIcons;
    widgets.showLabel = showLabel;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            widgets.dashCardFunc(
              'Previous',
              Icons.skip_previous,
              () async => await FlutterMediaController.previousTrack(),
              context,
              itemCount,
            ),
            widgets.dashCardFunc(
              'Play / Pause',
              Icons.play_arrow,
              // () async => await FlutterMediaController.togglePlayPause(),
              () async => MediaSessionController.toggle(),
              context,
              itemCount,
            ),
            widgets.dashCardFunc(
              'Next',
              Icons.skip_next,
              () async => await FlutterMediaController.nextTrack(),
              context,
              itemCount,
            ),
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
