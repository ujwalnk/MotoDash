import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moto_dash/commons/list_builder.dart';

class CallNavScreen extends StatefulWidget {
  const CallNavScreen({super.key});

  @override
  State<CallNavScreen> createState() => _CallNavScreenState();
}

class _CallNavScreenState extends State<CallNavScreen> {
  final bool showIcons = ConfigProvider.getShowIcons(Constants.kPathCallNav);
  final bool showLabel = ConfigProvider.getShowLabel(Constants.kPathCallNav);

  double fontSize = ConfigProvider.getFontSize;

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

    names = prefs.getStringList("fav_contact_names") ?? [];
    numbers = prefs.getStringList("fav_contact_numbers") ?? [];

    loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();

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
      backgroundColor: ConfigProvider.getBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
        child: widgets.dashView(true, [
          // -------------------------------
          // Favourites Button
          // -------------------------------
          widgets.dashCardFunc(
            'Favourites',
            [Icons.star_rounded],
            () => Navigator.pushNamed(context, Constants.kPathCallFav),
            context,
            itemCount,
          ),

          // -------------------------------
          // CALL LOG BUTTON
          // -------------------------------
          widgets.dashCardFunc(
            'Call Log',
            [Icons.history_rounded],
            () => Navigator.pushNamed(context, Constants.kPathCallLog),
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
