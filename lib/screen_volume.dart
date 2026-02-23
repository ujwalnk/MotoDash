import 'dart:async';
import 'package:flutter/material.dart';
import 'package:volume_controller/volume_controller.dart';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/commons/split_screen_observer.dart';
import 'package:moto_dash/service/global_services.dart';
import 'package:moto_dash/service/magent_intent_detector.dart';
import 'package:moto_dash/main.dart';

class VolumeScreen extends StatefulWidget {
  const VolumeScreen({super.key});

  @override
  State<VolumeScreen> createState() => _VolumeScreenState();
}

class _VolumeScreenState extends SplitScreenState<VolumeScreen>
    with RouteAware {
  bool showIcons = ConfigProvider.getShowIcons(Constants.kPathVolume);
  bool showLabel = ConfigProvider.getShowLabel(Constants.kPathVolume);

  int selectedIndex = ConfigProvider.getEnableMagnetGestures ? 0 : -1;

  StreamSubscription<AppIntent>? _intentSub;
  late List<VoidCallback> _actions;

  // -----------------------------
  // RouteAware lifecycle
  // -----------------------------

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _unsubscribe();
    super.dispose();
  }

  @override
  void didPush() => _subscribe();

  @override
  void didPopNext() => _subscribe();

  @override
  void didPushNext() => _unsubscribe();

  void _subscribe() {
    _intentSub = magnetService.intents.listen(_handleIntent);
  }

  void _unsubscribe() {
    _intentSub?.cancel();
    _intentSub = null;
  }

  // -----------------------------

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();
    const int itemCount = 4;

    widgets.showLabel = isSplitScreen ? false : showLabel;
    widgets.showIcons = isSplitScreen ? true : showIcons;

    // Single source of truth for actions
    _actions = [
      () async {
        final current = await VolumeController.instance.getVolume();
        await VolumeController.instance.setVolume(
          (current + 0.1).clamp(0.0, 1.0),
        );
      },
      () async {
        final current = await VolumeController.instance.getVolume();
        await VolumeController.instance.setVolume(
          (current - 0.1).clamp(0.0, 1.0),
        );
      },
      () async {
        final isMuted = await VolumeController.instance.isMuted();
        await VolumeController.instance.setMute(!isMuted);
      },
      () => Navigator.pop(context),
    ];

    return Scaffold(
      backgroundColor: ConfigProvider.getBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: widgets.dashView(isSplitScreen, [
          widgets.dashCardFunc(
            'Increase Volume',
            [Icons.add_rounded],
            _actions[0],
            context,
            itemCount,
            isSelected: selectedIndex == 0,
          ),
          widgets.dashCardFunc(
            'Decrease Volume',
            [Icons.remove_rounded],
            _actions[1],
            context,
            itemCount,
            isSelected: selectedIndex == 1,
          ),
          widgets.dashCardFunc(
            'Mute / Unmute',
            [Icons.volume_off_rounded],
            _actions[2],
            context,
            itemCount,
            isSelected: selectedIndex == 2,
          ),
          widgets.dashCardFunc(
            'Return',
            [Icons.undo_rounded],
            _actions[3],
            context,
            itemCount,
            isSelected: selectedIndex == 3,
          ),
        ]),
      ),
    );
  }

  // -----------------------------
  // Magnet Intent Handler
  // -----------------------------

  void _handleIntent(AppIntent intent) {
    switch (intent) {
      case AppIntent.next:
        setState(() {
          selectedIndex = (selectedIndex + 1) % _actions.length;
        });
        break;

      case AppIntent.select:
        _actions[selectedIndex]();
        break;

      case AppIntent.back:
        Navigator.pop(context);
        break;
    }
  }
}
