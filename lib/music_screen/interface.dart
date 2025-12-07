import 'package:flutter/material.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';
import 'package:moto_dash/commons/list_builder.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {

    DashWidgets widgets = DashWidgets();
    int itemCount = 6;
    widgets.showIcons = true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            widgets.dashCardRoute('Previous', Icons.skip_previous, '/phone', context, itemCount),
            widgets.dashCardRoute('Rewind', Icons.replay, '/music', context, itemCount),
            widgets.dashCardFunc('Play / Pause', Icons.play_arrow, () async => await FlutterMediaController.togglePlayPause(), context, itemCount),
            widgets.dashCardRoute('Fast Forward', Icons.forward_5, '/maps', context, itemCount),
            widgets.dashCardRoute('Next', Icons.skip_next, '/volume', context, itemCount),
            widgets.dashCardFunc('Return', Icons.undo, () => Navigator.pop(context), context, itemCount),
          ],
        ),
      ),
    );
  }
}