import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScreenSaver extends StatefulWidget {
  const ScreenSaver({super.key});

  @override
  State<ScreenSaver> createState() => _ScreenSaverState();
}

class _ScreenSaverState extends State<ScreenSaver>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  Offset _position = const Offset(0, 0);
  Timer? _timer;

  Color dotColor = Colors.red;

  late AnimationController _fadeController;
  late Animation<double> _opacity;

  Duration dotMoveDuration = const Duration(minutes: 2);

  List<Offset> lastPositions = [];

  static const double padding = 20.0;
  static const double radius = 10.0; // dot radius

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacity = Tween<double>(begin: 1, end: 0).animate(_fadeController);

    _loadPrefs().then((_) {
      _startTimer();

      // Initialize random starting position INSIDE padding boundaries
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeRandomStart();
        _animateMove();
      });
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(dotMoveDuration, (_) {
      _animateMove();
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      dotColor = Color(prefs.getInt("font_color") ?? Colors.red.toARGB32());

      final moveStr = prefs.getString("blank_time_minutes");
      final moveMinutes = int.tryParse(moveStr ?? "") ?? 2;
      dotMoveDuration = Duration(minutes: moveMinutes);
    });
  }

  // Pick FIRST position randomly inside padded area
  void _initializeRandomStart() {
    final size = MediaQuery.of(context).size;

    final minX = padding + radius;
    final maxX = size.width - padding - radius;

    final minY = padding + radius;
    final maxY = size.height - padding - radius;

    final start = Offset(
      minX + _random.nextDouble() * (maxX - minX),
      minY + _random.nextDouble() * (maxY - minY),
    );

    setState(() {
      _position = start;
      lastPositions = [start];
    });
  }

  Future<void> _animateMove() async {
    if (!mounted) return;

    await _fadeController.forward();
    _setRandomPosition();
    await _fadeController.reverse();
  }

  void _setRandomPosition() {
    if (!mounted) return;

    final size = MediaQuery.of(context).size;

    // Movement boundaries inside padding
    final minX = padding + radius;
    final maxX = size.width - 40 - radius;
    final minY = padding + radius;
    final maxY = size.height - 40 - radius;

    // Screen diagonal
    final diagonal = sqrt(size.width * size.width + size.height * size.height);

    // Up to last 5 recent positions
    final recent = [...lastPositions];
    if (recent.isEmpty) recent.add(_position);

    final List<Offset> candidates = [];

    for (final oldPos in recent) {
      // Random angle + distance (20–80% diagonal)
      final angle = _random.nextDouble() * pi * 2;
      final minDist = 0.20 * diagonal;
      final maxDist = 0.80 * diagonal;
      final dist = minDist + _random.nextDouble() * (maxDist - minDist);

      Offset p = Offset(
        oldPos.dx + dist * cos(angle),
        oldPos.dy + dist * sin(angle),
      );

      // Clamp within padded area
      p = Offset(
        p.dx.clamp(minX, maxX),
        p.dy.clamp(minY, maxY),
      );

      candidates.add(p);
    }

    // Pick candidate farthest from all recent positions
    double bestScore = -1;
    late Offset bestPoint;

    for (final c in candidates) {
      double minDist = double.infinity;

      for (final old in recent) {
        final d = (c - old).distance;
        if (d < minDist) minDist = d;
      }

      if (minDist > bestScore) {
        bestScore = minDist;
        bestPoint = c;
      }
    }

    setState(() {
      _position = bestPoint;

      // Keep last 5 positions
      lastPositions.add(bestPoint);
      if (lastPositions.length > 5) {
        lastPositions.removeAt(0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned(
                left: _position.dx - 10, // center the dot
                top: _position.dy - 10,
                child: FadeTransition(
                  opacity: _opacity,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
