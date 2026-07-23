// lib/features/routines/presentation/widgets/confetti_widget.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

class ConfettiWidget extends StatefulWidget {
  const ConfettiWidget({super.key});

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        setState(() {});
      });

    for (var i = 0; i < 45; i++) {
      _particles.add(
        _ConfettiParticle(
          x: 150,
          y: 20,
          vx: (_random.nextDouble() - 0.5) * 8.0,
          vy: -_random.nextDouble() * 6.0 - 2.0,
          color: HSLColor.fromAHSL(
            1,
            _random.nextDouble() * 360,
            0.8,
            0.6,
          ).toColor(),
          radius: _random.nextDouble() * 4.0 + 2.0,
        ),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ConfettiPainter(particles: _particles, progress: _controller.value),
    );
  }
}

class _ConfettiParticle {

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.radius,
  });
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double radius;

  void update() {
    x += vx;
    y += vy;
    vy += 0.2; // Gravity
    vx *= 0.98; // Air resistance
  }
}

class _ConfettiPainter extends CustomPainter {

  _ConfettiPainter({required this.particles, required this.progress});
  final List<_ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      p.update();
      paint.color = p.color.withValues(alpha: 1.0 - progress);
      canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
