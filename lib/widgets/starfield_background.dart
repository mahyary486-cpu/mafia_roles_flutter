import 'dart:math';
import 'package:flutter/material.dart';

/// A deep-space backdrop: a dark navy/purple gradient with a scatter of
/// twinkling stars, procedurally drawn (no image asset, so it costs
/// nothing in app size and scales to any screen).
class StarfieldBackground extends StatefulWidget {
  const StarfieldBackground({super.key});

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _random = Random(42); // fixed seed so stars don't jump around on rebuild

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _GalaxyPainter(progress: _controller.value, random: _random),
          size: Size.infinite,
        );
      },
    );
  }
}

class _GalaxyPainter extends CustomPainter {
  final double progress;
  final Random random;

  _GalaxyPainter({required this.progress, required this.random});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Deep-space gradient: near-black with a subtle indigo/purple glow.
    final gradient = RadialGradient(
      center: const Alignment(0.2, -0.6),
      radius: 1.3,
      colors: const [
        Color(0xFF1B1035),
        Color(0xFF10091F),
        Color(0xFF05050A),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // A fixed set of stars (seeded random so positions are stable), each
    // twinkling on its own phase offset.
    final starCount = (size.width * size.height / 3500).clamp(60, 220).toInt();
    final localRandom = Random(7); // separate stable seed for positions
    for (int i = 0; i < starCount; i++) {
      final dx = localRandom.nextDouble() * size.width;
      final dy = localRandom.nextDouble() * size.height;
      final baseRadius = localRandom.nextDouble() * 1.4 + 0.3;
      final phase = localRandom.nextDouble();
      final twinkle = (sin((progress + phase) * 2 * pi) + 1) / 2; // 0..1
      final opacity = 0.25 + twinkle * 0.65;

      canvas.drawCircle(
        Offset(dx, dy),
        baseRadius,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
