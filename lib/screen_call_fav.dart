import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/split_screen_observer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moto_dash/commons/list_builder.dart';

class FavContactsScreen extends StatefulWidget {
  const FavContactsScreen({super.key});

  @override
  State<FavContactsScreen> createState() => _FavContactsScreenState();
}

class _FavContactsScreenState extends SplitScreenState<FavContactsScreen> {
  final Color backgroundColor = ConfigProvider.getBackgroundColor;
  final Color fontColor = ConfigProvider.getFontColor;
  final Color borderColor = ConfigProvider.getOptionBorderColor;

  final bool showIcons = ConfigProvider.getShowIcons(Constants.kPathCallFav);
  final bool showLabel = ConfigProvider.getShowLabel(Constants.kPathCallFav);

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

    widgets.backgroundColor = backgroundColor;
    widgets.fontColor = fontColor;
    widgets.borderColor = borderColor;

    // Split Screen Settings
    if (isSplitScreen) {
      widgets.showLabel = true;
      widgets.showIcons = false;
    } else {
      widgets.showIcons = showIcons;
      widgets.showLabel = showLabel;
    }

    int itemCount = 2 + names.length;

    if (loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
        child: widgets.dashView(isSplitScreen, [
          // -------------------------------
          // LIST OF FAVOURITE CONTACTS
          // -------------------------------
          for (int i = 0; i < (isSplitScreen ? 4 : names.length); i++)
            widgets.dashCardFunc(
              isSplitScreen
                  ? (names[i].substring(
                      0,
                      names[i].length > 10 ? 10 : names[i].length,
                    ))
                  : names[i], // Title (name only)
              [Icons.person_rounded], // Simple icon (or customize)
              () async => await FlutterPhoneDirectCaller.callNumber(
                numbers[i],
              ), // Call directly
              context,
              itemCount,
            ),

          // const SizedBox(height: 10),
          if (!isSplitScreen)
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
            overrideShowIcons: true,
            overrideShowLabel: false,
          ),
        ]),
      ),
    );
  }
}
