import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/list_builder.dart';
import 'package:moto_dash/commons/split_screen_observer.dart';
import 'package:moto_dash/service/global_services.dart';
import 'package:moto_dash/service/magent_intent_detector.dart';
import 'package:moto_dash/main.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends SplitScreenState<MusicScreen> with RouteAware {
  bool showIcons = ConfigProvider.getShowIcons(Constants.kPathMusic);
  bool showLabel = ConfigProvider.getShowLabel(Constants.kPathMusic);

  static const MethodChannel _channel = MethodChannel('assistant.launcher');

  int selectedIndex = ConfigProvider.getEnableMagnetGestures ? 0 : -1;

  StreamSubscription<AppIntent>? _intentSub;
  late List<VoidCallback> _actions;

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

  @override
  Widget build(BuildContext context) {
    DashWidgets widgets = DashWidgets();
    const itemCount = 4;

    if (isSplitScreen) {
      widgets.showLabel = false;
      widgets.showIcons = true;
    } else {
      widgets.showIcons = showIcons;
      widgets.showLabel = showLabel;
    }

    _actions = [
      () async => await _channel.invokeMethod('previousTrack'),
      () async => await _channel.invokeMethod('togglePlayPause'),
      () async => await _channel.invokeMethod('nextTrack'),
      () => Navigator.pop(context),
    ];

    return Scaffold(
      backgroundColor: ConfigProvider.getBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: widgets.dashView(isSplitScreen, [
          widgets.dashCardFunc(
            'Previous',
            [Icons.skip_previous_rounded],
            _actions[0],
            context,
            itemCount,
            isSelected: selectedIndex == 0,
          ),
          widgets.dashCardFunc(
            'Play / Pause',
            [Icons.play_arrow_rounded, Icons.pause_rounded],
            _actions[1],
            context,
            itemCount,
            isSelected: selectedIndex == 1,
          ),
          widgets.dashCardFunc(
            'Next',
            [Icons.skip_next_rounded],
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
