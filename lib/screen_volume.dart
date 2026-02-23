import 'dart:async';
import 'package:flutter/material.dart';
import 'package:volume_controller/volume_controller.dart';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/dash_action.dart';
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

  // Never use late
  List<DashAction> _items = [];

  bool _didAutoSpeak = false;

  // ------------------------------------------------
  // RouteAware lifecycle
  // ------------------------------------------------

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
  void didPush() {
    _subscribe();
  }

  @override
  void didPushNext() {
    _unsubscribe();
  }

  @override
  void didPopNext() {
    _subscribe();
    _didAutoSpeak = false; // allow auto speak again
  }

  void _subscribe() {
    _intentSub = magnetService.intents.listen(_handleIntent);
  }

  void _unsubscribe() {
    _intentSub?.cancel();
    _intentSub = null;
  }

  // ------------------------------------------------
  // BUILD
  // ------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final DashWidgets widgets = DashWidgets();

    widgets.showLabel = isSplitScreen ? false : showLabel;
    widgets.showIcons = isSplitScreen ? true : showIcons;

    // -----------------------------------
    // DashAction list
    // -----------------------------------

    _items = [
      DashAction(
        label: 'Increase Volume',
        icons: [Icons.add_rounded],
        action: () async {
          final current = await VolumeController.instance.getVolume();
          await VolumeController.instance.setVolume(
            (current + 0.1).clamp(0.0, 1.0),
          );
        },
      ),
      DashAction(
        label: 'Decrease Volume',
        icons: [Icons.remove_rounded],
        action: () async {
          final current = await VolumeController.instance.getVolume();
          await VolumeController.instance.setVolume(
            (current - 0.1).clamp(0.0, 1.0),
          );
        },
      ),
      DashAction(
        label: 'Mute / Unmute',
        icons: [Icons.volume_off_rounded],
        action: () async {
          final isMuted = await VolumeController.instance.isMuted();
          await VolumeController.instance.setMute(!isMuted);
        },
      ),
      DashAction(
        label: 'Return',
        icons: [Icons.undo_rounded],
        action: () => Navigator.pop(context),
      ),
    ];

    // -----------------------------------
    // Safe auto-speak after first build
    // -----------------------------------

    if (!_didAutoSpeak && selectedIndex != -1 && _items.isNotEmpty) {
      _didAutoSpeak = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() => selectedIndex = 0);
        ttsService.speak(_items[0].label);
      });
    }

    return Scaffold(
      backgroundColor: ConfigProvider.getBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: widgets.dashView(
          isSplitScreen,
          List.generate(_items.length, (index) {
            return widgets.dashCardAction(
              _items[index],
              context,
              _items.length,
              isSelected: selectedIndex == index,
            );
          }),
        ),
      ),
    );
  }

  // ------------------------------------------------
  // Magnet Intent Handler
  // ------------------------------------------------

  void _handleIntent(AppIntent intent) {
    if (selectedIndex == -1 || _items.isEmpty) return;

    switch (intent) {
      case AppIntent.next:
        setState(() {
          selectedIndex = (selectedIndex + 1) % _items.length;
        });

        ttsService.speak(_items[selectedIndex].label);
        break;

      case AppIntent.select:
        _items[selectedIndex].action();
        break;

      case AppIntent.back:
        Navigator.pop(context);
        break;
    }
  }
}
