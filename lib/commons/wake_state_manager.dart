import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WakeStateManager extends StatefulWidget {
  const WakeStateManager({super.key});

  @override
  State<WakeStateManager> createState() => _WakeStateManagerState();
}

class _WakeStateManagerState extends State<WakeStateManager>     with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}