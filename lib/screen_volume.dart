import 'package:flutter/material.dart';
import 'package:moto_dash/commons/list_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volume_controller/volume_controller.dart';

class VolumeScreen extends StatefulWidget {
  const VolumeScreen({super.key});

  @override
  State<VolumeScreen> createState() => _VolumeScreenState();
}

class _VolumeScreenState extends State<VolumeScreen> {
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
      prefs.getInt("background_color") ?? Colors.black.toARGB32(),
    );
    fontColor = Color(prefs.getInt("font_color") ?? Colors.white.toARGB32());
    borderColor = Color(
      prefs.getInt("option_border_color") ?? Colors.white.toARGB32(),
    );

    showIcons = prefs.getBool("volume_show_icons") ?? true;
    showLabel = prefs.getBool("volume_show_label") ?? true;

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
              'Increase Volume',
              Icons.add,
              () async => await VolumeController.instance.setVolume(
                await VolumeController.instance.getVolume() + 0.1,
              ),
              context,
              itemCount,
            ),
            widgets.dashCardFunc(
              'Decrease Volume',
              Icons.remove,
              () async => await VolumeController.instance.setVolume(
                await VolumeController.instance.getVolume() - 0.1,
              ),
              context,
              itemCount,
            ),
            widgets.dashCardFunc(
              'Mute / Unmute',
              Icons.volume_off,
              () async => await VolumeController.instance.setMute(
                !(await VolumeController.instance.isMuted()),
              ),
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
