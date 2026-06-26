// Author: Ujwal N K
// Created:
// Screen saver with a moving dot

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart';

class ScreenSaver extends StatefulWidget {
  const ScreenSaver({super.key});

  @override
  State<ScreenSaver> createState() => _ScreenSaverState();
}

class _ScreenSaverState extends State<ScreenSaver> with SingleTickerProviderStateMixin {
  final Random _random = Random();

  Offset _position = Offset.zero;
  final Color _dotColor = ConfigProvider.dashboardFontColor;
  final Duration _moveInterval = Duration(seconds: ConfigProvider.screenSaverTimeout.toInt());

  late final AnimationController _fadeController;
  late final Animation<double> _opacity;

  static const double padding = 20.0;
  static const double radius = 10.0;

  bool _running = false;

  @override
  void initState() {
    super.initState();

    // Dot animation on move
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _opacity = Tween(begin: 1.0, end: 0.0).animate(_fadeController);

    _init();
  }

  Future<void> _init() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRandomStart();
      _runLoop();
    });
  }

  void _initializeRandomStart() => _setRandomPosition();

  Future<void> _runLoop() async {
    if (_running) return;
    _running = true;

    while (mounted) {
      await Future.delayed(_moveInterval);
      if (!mounted) break;
      await _animateMove();
    }
  }

  Future<void> _animateMove() async {
    await _fadeController.forward();
    _setRandomPosition();
    if (!mounted) return;
    await _fadeController.reverse();
  }

  void _setRandomPosition() {
    final size = MediaQuery.of(context).size;

    // Screen boundaries with padding for the moving dot
    final double minX = padding + radius;
    final double maxX = size.width - padding - radius;
    final double minY = padding + radius;
    final double maxY = size.height - padding - radius;

    // Random next move for the dot
    setState(() {
      _position = Offset(minX + _random.nextDouble() * (maxX - minX), minY + _random.nextDouble() * (maxY - minY));
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => Navigator.of(context).pop(),
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
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _dotColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
