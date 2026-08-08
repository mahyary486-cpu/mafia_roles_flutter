import 'dart:math';
import 'package:flutter/material.dart';

/// Shows a one-time celebration dialog when the game ends: a colored
/// status card (blue = citizens, red = mafia, purple = independent) with
/// falling confetti, plus a fireworks burst on top if the winning side
/// had a "clean sheet" (never lost a single member all game).
///
/// This is only ever invoked from an explicit button press (End Game), so
/// it naturally runs exactly once per game - there's no risk of it firing
/// again on a rebuild, since showDialog isn't tied to this screen's state.
Future<void> showWinCelebrationDialog(
  BuildContext context, {
  required Color color,
  required String titleEn,
  required String titleFa,
  required bool cleanSheet,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _WinCelebrationDialog(
      color: color,
      titleEn: titleEn,
      titleFa: titleFa,
      cleanSheet: cleanSheet,
    ),
  );
}

class _WinCelebrationDialog extends StatefulWidget {
  final Color color;
  final String titleEn;
  final String titleFa;
  final bool cleanSheet;

  const _WinCelebrationDialog({
    required this.color,
    required this.titleEn,
    required this.titleFa,
    required this.cleanSheet,
  });

  @override
  State<_WinCelebrationDialog> createState() => _WinCelebrationDialogState();
}

class _WinCelebrationDialogState extends State<_WinCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _confetti;
  late final List<_FireworkBurst> _fireworks;

  @override
  void initState() {
    super.initState();
    // Built once, here, when the dialog first appears - not tied to any
    // parent rebuild, so it can only ever play once per End Game press.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();

    final random = Random();
    _confetti = List.generate(70, (i) {
      const colors = [
        Colors.amber,
        Colors.pinkAccent,
        Colors.lightBlueAccent,
        Colors.greenAccent,
        Colors.orangeAccent,
        Colors.white,
      ];
      return _ConfettiPiece(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.35,
        fallSpeed: 0.55 + random.nextDouble() * 0.6,
        drift: (random.nextDouble() - 0.5) * 0.5,
        rotationSpeed: (random.nextDouble() - 0.5) * 8,
        color: colors[random.nextInt(colors.length)],
        size: 5 + random.nextDouble() * 7,
      );
    });

    _fireworks = widget.cleanSheet
        ? List.generate(5, (i) {
            const colors = [Colors.amber, Colors.cyanAccent, Colors.pinkAccent, Colors.white];
            return _FireworkBurst(
              x: 0.15 + random.nextDouble() * 0.7,
              y: 0.15 + random.nextDouble() * 0.4,
              delay: random.nextDouble() * 1.8,
              color: colors[random.nextInt(colors.length)],
            );
          })
        : const [];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _CelebrationPainter(
                progress: _controller.value,
                confetti: _confetti,
                fireworks: _fireworks,
              ),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.color, width: 3),
                boxShadow: [
                  BoxShadow(color: widget.color.withOpacity(0.6), blurRadius: 20),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.titleEn,
                    style: TextStyle(color: widget.color, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.titleFa, style: TextStyle(color: widget.color, fontSize: 16)),
                  if (widget.cleanSheet) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Clean Sheet! / بدون هیچ باختی!',
                      style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continue / ادامه'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPiece {
  final double x, delay, fallSpeed, drift, rotationSpeed, size;
  final Color color;
  _ConfettiPiece({
    required this.x,
    required this.delay,
    required this.fallSpeed,
    required this.drift,
    required this.rotationSpeed,
    required this.color,
    required this.size,
  });
}

class _FireworkBurst {
  final double x, y, delay;
  final Color color;
  _FireworkBurst({required this.x, required this.y, required this.delay, required this.color});
}

class _CelebrationPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiPiece> confetti;
  final List<_FireworkBurst> fireworks;

  _CelebrationPainter({
    required this.progress,
    required this.confetti,
    required this.fireworks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in confetti) {
      final span = (1 - piece.delay).clamp(0.01, 1.0);
      final t = ((progress - piece.delay).clamp(0.0, 1.0)) / span;
      if (t <= 0) continue;
      final y = t * piece.fallSpeed * size.height * 1.3;
      final x = piece.x * size.width + piece.drift * size.width * t;
      final opacity = t > 0.85 ? ((1 - t) / 0.15).clamp(0.0, 1.0) : 1.0;
      final paint = Paint()..color = piece.color.withOpacity(opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.rotationSpeed * progress * 2 * pi);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: piece.size, height: piece.size * 0.5),
        paint,
      );
      canvas.restore();
    }

    for (final burst in fireworks) {
      final span = (1 - burst.delay).clamp(0.01, 1.0);
      final t = ((progress - burst.delay).clamp(0.0, 1.0)) / span;
      if (t <= 0 || t >= 1) continue;
      final center = Offset(burst.x * size.width, burst.y * size.height);
      final radius = t * size.width * 0.22;
      final opacity = (1 - t).clamp(0.0, 1.0);
      for (int i = 0; i < 16; i++) {
        final angle = (i / 16) * 2 * pi;
        final p = center + Offset(cos(angle), sin(angle)) * radius;
        final paint = Paint()..color = burst.color.withOpacity(opacity);
        canvas.drawCircle(p, 2.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
