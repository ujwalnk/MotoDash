import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:moto_dash/service/timer.dart';

class ScreenSaver extends StatefulWidget {
  const ScreenSaver({super.key});

  @override
  State<ScreenSaver> createState() => _ScreenSaverState();
}

class _ScreenSaverState extends State<ScreenSaver>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();

  Offset _position = Offset.zero;
  Color _dotColor = Colors.red;

  late final AnimationController _fadeController;
  late final Animation<double> _opacity;

  Duration _moveInterval = const Duration(minutes: 2);

  static const double padding = 20.0;
  static const double radius = 10.0;

  bool _running = false;
  bool _stopped = false;

  @override
  void initState() {
    super.initState();

    // 🔴 Disable idle timer while saver is active
    IdleTimer.instance.setEnabled(false);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacity = Tween(begin: 1.0, end: 0.0).animate(_fadeController);

    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    _dotColor = Color(prefs.getInt("font_color") ?? Colors.red.toARGB32());

    final moveStr = prefs.getString("blank_time_minutes");
    final moveMinutes = int.tryParse(moveStr ?? "") ?? 2;
    _moveInterval = Duration(minutes: moveMinutes);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRandomStart();
      _runLoop();
    });
  }

  void _initializeRandomStart() {
    final size = MediaQuery.of(context).size;

    final minX = padding + radius;
    final maxX = size.width - padding - radius;
    final minY = padding + radius;
    final maxY = size.height - padding - radius;

    setState(() {
      _position = Offset(
        minX + _random.nextDouble() * (maxX - minX),
        minY + _random.nextDouble() * (maxY - minY),
      );
    });
  }

  Future<void> _runLoop() async {
    if (_running) return;
    _running = true;

    while (mounted && !_stopped) {
      await Future.delayed(_moveInterval);
      if (!mounted || _stopped) break;
      await _animateMove();
    }
  }

  Future<void> _animateMove() async {
    if (_stopped) return;

    await _fadeController.forward();
    if (_stopped) return;

    _setRandomPosition();

    await _fadeController.reverse();
  }

  void _setRandomPosition() {
    final size = MediaQuery.of(context).size;

    final minX = padding + radius;
    final maxX = size.width - padding - radius;
    final minY = padding + radius;
    final maxY = size.height - padding - radius;

    setState(() {
      _position = Offset(
        minX + _random.nextDouble() * (maxX - minX),
        minY + _random.nextDouble() * (maxY - minY),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();

    // 🟢 Re-enable idle timer when saver exits
    IdleTimer.instance.setEnabled(true);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        _stopped = true;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned(
              left: _position.dx - radius,
              top: _position.dy - radius,
              child: FadeTransition(
                opacity: _opacity,
                child: Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _dotColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
