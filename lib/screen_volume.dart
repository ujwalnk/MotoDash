import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/commons/split_screen_observer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volume_controller/volume_controller.dart';

class VolumeScreen extends StatefulWidget {
  const VolumeScreen({super.key});

  @override
  State<VolumeScreen> createState() => _VolumeScreenState();
}

class _VolumeScreenState extends SplitScreenState<VolumeScreen> {
  Color backgroundColor = ConfigProvider.getBackgroundColor;
  Color fontColor = ConfigProvider.getFontColor;
  Color borderColor = ConfigProvider.getOptionBorderColor;

  bool showIcons = ConfigProvider.getShowIcons(Constants.kPathVolume);
  bool showLabel = ConfigProvider.getShowLabel(Constants.kPathVolume);

  double fontSize = ConfigProvider.getFontSize;

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();
    int itemCount = 4;

    // Set Widget properties
    widgets.backgroundColor = backgroundColor;
    widgets.fontColor = fontColor;
    widgets.borderColor = borderColor;

    // Split Screen Settings
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
            'Increase Volume',
            [Icons.add_rounded],
            () async => await VolumeController.instance.setVolume(
              await VolumeController.instance.getVolume() + 0.1,
            ),
            context,
            itemCount,
          ),
          widgets.dashCardFunc(
            'Decrease Volume',
            [Icons.remove_rounded],
            () async => await VolumeController.instance.setVolume(
              await VolumeController.instance.getVolume() - 0.1,
            ),
            context,
            itemCount,
          ),
          widgets.dashCardFunc(
            'Mute / Unmute',
            [Icons.volume_off_rounded],
            () async => await VolumeController.instance.setMute(
              !(await VolumeController.instance.isMuted()),
            ),
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
