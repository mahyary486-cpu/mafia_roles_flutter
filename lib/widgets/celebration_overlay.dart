import 'dart:math';
import 'package:flutter/material.dart';

/// Pushes a brief, non-interactive celebration overlay (confetti, plus
/// fireworks if [fireworks] is true) tinted with [color] for the winning
/// side, then pops itself automatically. Await the returned future to
/// know when it's done before moving on (e.g. to actually end the game).
Future<void> showCelebration(
  BuildContext context, {
  required Color color,
  required bool fireworks,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: _CelebrationOverlay(color: color, fireworks: fireworks),
        );
      },
    ),
  );
}

class _CelebrationOverlay extends StatefulWidget {
  final Color color;
  final bool fireworks;

  const _CelebrationOverlay({required this.color, required this.fireworks});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Confetto> _confetti;
  late final List<_Burst> _bursts;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final duration = widget.fireworks
        ? const Duration(milliseconds: 3400)
        : const Duration(milliseconds: 2400);
    _controller = AnimationController(vsync: this, duration: duration);
    final random = Random();

    final palette = [
      widget.color,
      Colors.white,
      Colors.amber,
      widget.color.withOpacity(0.7),
    ];
    _confetti = List.generate(90, (i) {
      return _Confetto(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.3,
        fallSpeed: 0.6 + random.nextDouble() * 0.6,
        drift: (random.nextDouble() - 0.5) * 0.4,
        size: 5 + random.nextDouble() * 6,
        color: palette[random.nextInt(palette.length)],
        spin: (random.nextDouble() - 0.5) * 10,
      );
    });

    _bursts = widget.fireworks
        ? List.generate(4, (i) {
            return _Burst(
              center: Offset(0.2 + random.nextDouble() * 0.6, 0.2 + random.nextDouble() * 0.35),
              startAt: 0.15 + i * 0.2,
              color: palette[random.nextInt(palette.length)],
            );
          })
        : const [];

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_finished) {
        _finished = true;
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _CelebrationPainter(
              progress: _controller.value,
              confetti: _confetti,
              bursts: _bursts,
            ),
          );
        },
      ),
    );
  }
}

class _Confetto {
  final double x, delay, fallSpeed, drift, size, spin;
  final Color color;
  _Confetto({
    required this.x,
    required this.delay,
    required this.fallSpeed,
    required this.drift,
    required this.size,
    required this.color,
    required this.spin,
  });
}

class _Burst {
  final Offset center; // fractional (0..1) position
  final double startAt; // fractional time (0..1) the burst begins
  final Color color;
  _Burst({required this.center, required this.startAt, required this.color});
}

class _CelebrationPainter extends CustomPainter {
  final double progress;
  final List<_Confetto> confetti;
  final List<_Burst> bursts;

  _CelebrationPainter({
    required this.progress,
    required this.confetti,
    required this.bursts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Falling confetti rectangles.
    for (final c in confetti) {
      final t = ((progress - c.delay) / (1 - c.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final y = t * c.fallSpeed * size.height * 1.3;
      final x = c.x * size.width + c.drift * y;
      final opacity = t > 0.85 ? (1 - t) / 0.15 : 1.0;
      final paint = Paint()..color = c.color.withOpacity(opacity.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c.spin * t * pi);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.5), paint);
      canvas.restore();
    }

    // Firework bursts.
    for (final b in bursts) {
      final t = ((progress - b.startAt) / 0.35).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final center = Offset(b.center.dx * size.width, b.center.dy * size.height);
      final radius = t * size.width * 0.22;
      final opacity = (1 - t);
      final particlePaint = Paint()..color = b.color.withOpacity(opacity);
      const particleCount = 24;
      for (int i = 0; i < particleCount; i++) {
        final angle = (i / particleCount) * 2 * pi;
        final p = center + Offset(cos(angle), sin(angle)) * radius;
        canvas.drawCircle(p, 2.5, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
