import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/commons/split_screen_observer.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends SplitScreenState<MusicScreen> {
  Color backgroundColor = ConfigProvider.getBackgroundColor;
  Color fontColor = ConfigProvider.getFontColor;
  Color borderColor = ConfigProvider.getOptionBorderColor;

  bool showIcons = ConfigProvider.getShowIcons(Constants.kPathMusic);
  bool showLabel = ConfigProvider.getShowLabel(Constants.kPathMusic);

  double fontSize = ConfigProvider.getFontSize;

  static const MethodChannel _channel = MethodChannel('assistant.launcher');

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();
    int itemCount = 4;

    // Set Widget properties
    widgets.backgroundColor = backgroundColor;
    widgets.fontColor = fontColor;
    widgets.borderColor = borderColor;
    if (isSplitScreen) {
      widgets.showLabel = false;
      widgets.showIcons = true;
    } else {
      widgets.showIcons = showIcons;
      widgets.showLabel = showLabel;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
        child: widgets.dashView(isSplitScreen, [
          widgets.dashCardFunc(
            'Previous',
            [Icons.skip_previous_rounded],
            () async => await _channel.invokeMethod('previousTrack'),
            context,
            itemCount,
          ),
          widgets.dashCardFunc(
            'Play / Pause',
            [Icons.play_arrow_rounded, Icons.pause_rounded],
            () async => await _channel.invokeMethod('togglePlayPause'),
            context,
            itemCount,
          ),
          widgets.dashCardFunc(
            'Next',
            [Icons.skip_next_rounded],
            () async => await _channel.invokeMethod('nextTrack'),
            context,
            itemCount,
          ),
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
