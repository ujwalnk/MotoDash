import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class MovingDotScreen extends StatefulWidget {
  const MovingDotScreen({super.key});

  @override
  State<MovingDotScreen> createState() => _MovingDotScreenState();
}

class _MovingDotScreenState extends State<MovingDotScreen> {
  final Random _random = Random();
  Offset _position = Offset.zero;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _setRandomPosition();

    // Move every 2 minutes
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      _setRandomPosition();
    });
  }

  void _setRandomPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      const double radius = 10;

      setState(() {
        _position = Offset(
          radius + _random.nextDouble() * (size.width - radius * 2),
          radius + _random.nextDouble() * (size.height - radius * 2),
        );
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned(
              left: _position.dx,
              top: _position.dy,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
