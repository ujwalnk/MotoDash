import 'package:flutter/material.dart';

class DashWidgets {
  // static final DashWidgets _instance = DashWidgets._internal();

  // factory DashWidgets() {
  //   return _instance;
  // }

  // DashWidgets._internal();

  Color? backgroundColor;
  Color? fontColor;
  Color? borderColor;

  bool showIcons = true;
  bool showLabel = true;

  Widget dashListView(List<Widget> children) {
    return ListView(padding: const EdgeInsets.all(10), children: children);
  }

  Widget dashCardRoute(
    String title,
    List<IconData> icons,
    String route,
    BuildContext context,
    int itemCount, {
    String? routeOnLongTap,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    debugPrint("Long Tap Route: $routeOnLongTap");
    return InkWell(
      onTap: () {
        if (route != "/home") {
          Navigator.pushNamed(context, route);
        } else {
          Navigator.pop(context);
        }
      },
      onDoubleTap: () {
        debugPrint("Double Tap on $title, $routeOnLongTap");
        if (routeOnLongTap != null) {
          Navigator.pushNamed(context, routeOnLongTap);
        }
      },
      child: SizedBox(
        height: screenHeight / (itemCount) - 10,
        child: Card(
          color: backgroundColor ?? Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor ?? Colors.grey, width: 1),
          ),
          child: Center(child: dashListTile(icons, title)),
        ),
      ),
    );
  }

  Widget dashCardFunc(
    String title,
    List<IconData> icons,
    Function() onTap,
    BuildContext context,
    int itemCount, {
    Function()? onLongPress,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: screenHeight / (itemCount) - 10,
        child: Card(
          color: backgroundColor ?? Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor ?? Colors.grey, width: 1),
          ),
          child: Center(child: dashListTile(icons, title)),
        ),
      ),
    );
  }

  ListTile dashListTile(List<IconData> icons, String title) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0), // Add padding
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the row
        children: [
          if (showIcons)
            for (IconData icon in icons)
              Icon(
                icon,
                color: fontColor ?? Colors.white,
                size: 40,
              ), // Show icon if enabled
          SizedBox(width: 8.0), // Space between icon and text
          if (showLabel)
            Text(
              title,
              style: TextStyle(color: fontColor ?? Colors.white, fontSize: 30),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
