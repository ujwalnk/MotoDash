import 'package:flutter/material.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';
import 'package:moto_dash/commons/list_builder.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {

    DashWidgets widgets = DashWidgets();
    int itemCount = 4;
    widgets.showIcons = true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            widgets.dashCardFunc('Previous', Icons.skip_previous, () async => await FlutterMediaController.previousTrack(), context, itemCount),
            widgets.dashCardFunc('Play / Pause', Icons.play_arrow, () async => await FlutterMediaController.togglePlayPause(), context, itemCount),
            widgets.dashCardFunc('Next', Icons.skip_next, () async => await FlutterMediaController.nextTrack(), context, itemCount),
            widgets.dashCardFunc('Return', Icons.undo, () => Navigator.pop(context), context, itemCount),
          ],
        ),
      ),
    );
  }
}