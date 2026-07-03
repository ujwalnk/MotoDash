// Author: Ujwal N K
// Created:

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

abstract class SplitScreenState<T extends StatefulWidget> extends State<T> with WidgetsBindingObserver {
  bool isSplitScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateSplitScreenState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _updateSplitScreenState();
  }

  Future<void> _updateSplitScreenState() async {
    final value =
        await const MethodChannel('in.madilu.motodash/assistant').invokeMethod<bool>('getSplitScreenState') ?? false;

    debugPrint("Native returned: $value");
    debugPrint("Current state: $isSplitScreen");

    if (!mounted) {
      debugPrint("Returning");
      return;
    }

    setState(() {
      isSplitScreen = value;
      debugPrint("Running in split screen");
    });
  }
}
