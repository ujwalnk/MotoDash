import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moto_dash/commons/list_builder.dart';

class CallNavScreen extends StatefulWidget {
  const CallNavScreen({super.key});

  @override
  State<CallNavScreen> createState() => _CallNavScreenState();
}

class _CallNavScreenState extends State<CallNavScreen> {
  Color backgroundColor = Colors.black;
  Color fontColor = Colors.white;
  Color borderColor = Colors.white;

  bool showIcons = true;
  bool showLabel = true;

  double fontSize = 16.0;

  List<String> names = [];
  List<String> numbers = [];

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

    showIcons = prefs.getBool("fav_show_icons") ?? true;
    showLabel = prefs.getBool("fav_show_label") ?? true;

    fontSize = double.tryParse(prefs.getString("font_size") ?? "16.0") ?? 16.0;

    names = prefs.getStringList("fav_contact_names") ?? [];
    numbers = prefs.getStringList("fav_contact_numbers") ?? [];

    loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();

    widgets.backgroundColor = backgroundColor;
    widgets.fontColor = fontColor;
    widgets.borderColor = borderColor;
    widgets.showIcons = showIcons;
    widgets.showLabel = false;

    int itemCount = 2 + names.length;

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
        child: widgets.dashView(true, [
          // -------------------------------
          // Favourites Button
          // -------------------------------
          widgets.dashCardFunc(
            'Favourites',
            [Icons.star_rounded],
            () {
              Navigator.pushNamed(context, "/phone_fav");
            },
            context,
            itemCount,
          ),

          // -------------------------------
          // CALL LOG BUTTON
          // -------------------------------
          widgets.dashCardFunc(
            'Call Log',
            [Icons.history_rounded],
            () {
              Navigator.pushNamed(context, "/phone_log");
            },
            context,
            itemCount,
          ),

          // -------------------------------
          // RETURN BUTTON
          // -------------------------------
          widgets.dashCardFunc(
            'Return',
            [Icons.undo_rounded],
            () => Navigator.pop(context),
            context,
            itemCount,
          ),
        ]),
      ),
    );
  }
}
