import 'dart:math';
import 'package:flutter/material.dart';

/// Wraps a screen's body with a dark, twinkling galaxy/nebula backdrop
/// (entirely code-drawn - no image asset, so the app stays tiny) plus the
/// club logo shown faintly on top of it. Used on every screen so the app
/// has a consistent branded look instead of a flat black backdrop.
class AppBackground extends StatefulWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFF040409)),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _GalaxyPainter(_controller.value),
            ),
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0.32,
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _GalaxyPainter extends CustomPainter {
  final double progress;

  static final List<_Star> _stars = _generateStars(140);
  static final List<_Streak> _streaks = _generateStreaks(6);

  _GalaxyPainter(this.progress);

  static List<_Star> _generateStars(int count) {
    final random = Random(42);
    return List.generate(count, (i) {
      return _Star(
        dx: random.nextDouble(),
        dy: random.nextDouble(),
        size: 0.5 + random.nextDouble() * 1.8,
        phase: random.nextDouble(),
        speed: 0.4 + random.nextDouble() * 1.3,
      );
    });
  }

  static List<_Streak> _generateStreaks(int count) {
    final random = Random(7);
    return List.generate(count, (i) {
      return _Streak(
        dx: random.nextDouble(),
        dy: random.nextDouble(),
        length: 40 + random.nextDouble() * 90,
        angle: (random.nextDouble() - 0.5) * 0.6 + pi / 4,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final coreCenter = Offset(size.width * 0.5, size.height * 0.38);
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD08A).withOpacity(0.20),
          const Color(0xFFB8722E).withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(radius: size.width * 0.55, center: coreCenter));
    canvas.drawCircle(coreCenter, size.width * 0.55, corePaint);

    final nebulaSpots = [
      (Offset(size.width * 0.18, size.height * 0.65), const Color(0xFF3A5CC9)),
      (Offset(size.width * 0.82, size.height * 0.25), const Color(0xFF7C3AED)),
      (Offset(size.width * 0.75, size.height * 0.78), const Color(0xFF1E88A8)),
    ];
    for (final (center, color) in nebulaSpots) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(0.14), Colors.transparent],
        ).createShader(Rect.fromCircle(radius: size.width * 0.35, center: center));
      canvas.drawCircle(center, size.width * 0.35, paint);
    }

    for (final streak in _streaks) {
      final start = Offset(streak.dx * size.width, streak.dy * size.height);
      final end = start +
          Offset(cos(streak.angle), sin(streak.angle)) * streak.length;
      final streakPaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withOpacity(0.25), Colors.transparent],
        ).createShader(Rect.fromPoints(start, end))
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, streakPaint);
    }

    for (final star in _stars) {
      final twinkle = (sin((progress * star.speed + star.phase) * 2 * pi) + 1) / 2;
      final opacity = 0.25 + twinkle * 0.7;
      final paint = Paint()..color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Star {
  final double dx, dy, size, phase, speed;
  _Star({required this.dx, required this.dy, required this.size, required this.phase, required this.speed});
}

class _Streak {
  final double dx, dy, length, angle;
  _Streak({required this.dx, required this.dy, required this.length, required this.angle});
}
