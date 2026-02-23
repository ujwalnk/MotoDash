// FULL MUSIC FILE (magnet-aware)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/dash_action.dart';
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

  List<DashAction> _items = [];
  bool _didAutoSpeak = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _intentSub?.cancel();
    super.dispose();
  }

  @override
  void didPush() => _subscribe();

  @override
  void didPushNext() => _unsubscribe();

  @override
  void didPopNext() {
    _subscribe();
    _didAutoSpeak = false;
    _maybeSpeakFirst();
  }

  void _subscribe() {
    _intentSub = magnetService.intents.listen(_handleIntent);
  }

  void _unsubscribe() {
    _intentSub?.cancel();
    _intentSub = null;
  }

  void _handleIntent(AppIntent intent) {
    if (selectedIndex == -1 || _items.isEmpty) return;

    switch (intent) {
      case AppIntent.next:
        setState(() {
          selectedIndex = (selectedIndex + 1) % _items.length;
        });
        ttsService.stop();
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

  void _maybeSpeakFirst() {
    if (lastNavigationWasMagnet &&
        !_didAutoSpeak &&
        selectedIndex != -1 &&
        _items.isNotEmpty) {
      _didAutoSpeak = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => selectedIndex = 0);
        ttsService.stop();
        ttsService.speak(_items[0].label);
        lastNavigationWasMagnet = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgets = DashWidgets();

    widgets.showIcons = isSplitScreen ? true : showIcons;
    widgets.showLabel = isSplitScreen ? false : showLabel;

    _items = [
      DashAction(
        label: 'Previous',
        icons: [Icons.skip_previous_rounded],
        action: () async => await _channel.invokeMethod('previousTrack'),
      ),
      DashAction(
        label: 'Play Pause',
        icons: [Icons.play_arrow_rounded, Icons.pause_rounded],
        action: () async => await _channel.invokeMethod('togglePlayPause'),
      ),
      DashAction(
        label: 'Next',
        icons: [Icons.skip_next_rounded],
        action: () async => await _channel.invokeMethod('nextTrack'),
      ),
      DashAction(
        label: 'Return',
        icons: [Icons.undo_rounded],
        action: () => Navigator.pop(context),
      ),
    ];

    _maybeSpeakFirst();

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
}
