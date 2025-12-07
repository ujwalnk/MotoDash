import 'package:flutter/material.dart';

class DashWidgets {
  static final DashWidgets _instance = DashWidgets._internal();

  factory DashWidgets() {
    return _instance;
  }

  DashWidgets._internal();

  Color? backgroundColor;
  Color? fontColor;
  Color? borderColor;
  bool showIcons = false;

  Widget dashListView(List<Widget> children) {
    return ListView(padding: const EdgeInsets.all(10), children: children);
  }

  Widget dashCardRoute(
    String title,
    IconData icon,
    String route,
    BuildContext context,
    int itemCount,
    {String? routeOnLongTap}
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () {
        if (route != "/home") {
          Navigator.pushNamed(context, route);
        } else {
          Navigator.pop(context);
        }
      },
      onHorizontalDragEnd: (_) {
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
          child: Center(child: dashListTile(icon, title)),
        ),
      ),
    );
  }

  Widget dashCardFunc(
    String title,
    IconData icon,
    Function() onTap,
    BuildContext context,
    int itemCount,
    {Function()? onLongPress}
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: screenHeight / (itemCount) - 10,
        child: Card(
          color: backgroundColor ?? Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor ?? Colors.grey, width: 1),
          ),
          child: Center(child: dashListTile(icon, title)),
        ),
      ),
    );
  }

  ListTile dashListTile(IconData icon, String title) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0), // Add padding
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the row
        children: [
          if (showIcons)
            Icon(
              icon,
              color: fontColor ?? Colors.white,
              size: 40,
            ), // Show icon if enabled
          SizedBox(width: 8.0), // Space between icon and text
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
