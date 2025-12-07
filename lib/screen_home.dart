import 'package:flutter/material.dart';
import 'package:moto_dash/commons/list_builder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    DashWidgets widgets = DashWidgets();
    int itemCount = 5;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            widgets.dashCardRoute('Phone', Icons.phone, '/phone', context, itemCount),
            widgets.dashCardRoute('Music', Icons.music_note, '/music', context, itemCount),
            widgets.dashCardRoute('Voice Note', Icons.mic, '/voicenote', context, itemCount),
            widgets.dashCardRoute('Maps', Icons.map, '/maps', context, itemCount),
            widgets.dashCardRoute('Volume', Icons.volume_up, '/volume', context, itemCount, routeOnLongTap: "/settings"),
          ],
        ),
      ),
    );
  }
}
