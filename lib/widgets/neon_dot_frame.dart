import 'dart:math';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Wraps [child] in a rounded frame decorated with a small number of
/// glowing dots that continuously orbit the perimeter, cycling through a
/// 7-color neon palette at a moderate, steady speed.
///
/// This is a lightweight custom-painted effect (no images, no packages) -
/// cheap to run and keeps the app's asset footprint at zero for this.
class NeonDotFrame extends StatefulWidget {
  final Widget child;
  final int dotCount;
  final double dotSize;
  final double borderRadius;
  final Duration period;

  const NeonDotFrame({
    super.key,
    required this.child,
    this.dotCount = 4,
    this.dotSize = 7,
    this.borderRadius = 20,
    this.period = const Duration(seconds: 6),
  });

  @override
  State<NeonDotFrame> createState() => _NeonDotFrameState();
}

class _NeonDotFrameState extends State<NeonDotFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
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
          foregroundPainter: _OrbitingDotsPainter(
            progress: _controller.value,
            dotCount: widget.dotCount,
            dotSize: widget.dotSize,
            borderRadius: widget.borderRadius,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _OrbitingDotsPainter extends CustomPainter {
  final double progress; // 0..1, one full lap
  final int dotCount;
  final double dotSize;
  final double borderRadius;

  _OrbitingDotsPainter({
    required this.progress,
    required this.dotCount,
    required this.dotSize,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    // 1) The glowing "neon tube" border itself - a rotating rainbow
    // gradient traced along the edge, so the square's sides look lit up,
    // not just the orbiting dots.
    final sweepColors = [
      ...AppColors.neonRainbow,
      AppColors.neonRainbow.first,
    ];
    final gradient = SweepGradient(
      colors: sweepColors,
      transform: GradientRotation(progress * 2 * pi),
    );
    final borderRect = Offset.zero & size;
    final glowBorderPaint = Paint()
      ..shader = gradient.createShader(borderRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final sharpBorderPaint = Paint()
      ..shader = gradient.createShader(borderRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rect, glowBorderPaint);
    canvas.drawRRect(rect, sharpBorderPaint);

    // 2) The orbiting glowing dots on top of the lit border.
    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final total = metric.length;

    for (int i = 0; i < dotCount; i++) {
      final offsetFraction =
          (progress + i / dotCount) % 1.0; // spread dots evenly, rotating
      final distance = offsetFraction * total;
      final tangent = metric.getTangentForOffset(distance);
      if (tangent == null) continue;

      // Cycle through the 7-color neon palette, offset per dot so each
      // glows a slightly different hue at any moment.
      final colorProgress = (progress * AppColors.neonRainbow.length + i) %
          AppColors.neonRainbow.length;
      final colorIndex = colorProgress.floor();
      final nextIndex = (colorIndex + 1) % AppColors.neonRainbow.length;
      final t = colorProgress - colorIndex;
      final color = Color.lerp(
        AppColors.neonRainbow[colorIndex],
        AppColors.neonRainbow[nextIndex],
        t,
      )!;

      final glowPaint = Paint()
        ..color = color.withOpacity(0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      final dotPaint = Paint()..color = color;

      canvas.drawCircle(tangent.position, dotSize * 1.8, glowPaint);
      canvas.drawCircle(tangent.position, dotSize, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitingDotsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// A handful of small star icons that twinkle through the neon palette -
/// used to decorate the credit block in the rulebook. Simpler than the
/// orbiting-dot frame: just fades/cycles color in place, no motion.
class TwinklingStarRow extends StatefulWidget {
  final int count;
  const TwinklingStarRow({super.key, this.count = 5});

  @override
  State<TwinklingStarRow> createState() => _TwinklingStarRowState();
}

class _TwinklingStarRowState extends State<TwinklingStarRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.count, (i) {
            final colorProgress =
                (_controller.value * AppColors.neonRainbow.length +
                        i * 1.3) %
                    AppColors.neonRainbow.length;
            final colorIndex = colorProgress.floor();
            final nextIndex = (colorIndex + 1) % AppColors.neonRainbow.length;
            final t = colorProgress - colorIndex;
            final color = Color.lerp(
              AppColors.neonRainbow[colorIndex],
              AppColors.neonRainbow[nextIndex],
              t,
            )!;
            final scale = 0.7 + 0.3 * sin((_controller.value + i / widget.count) * 2 * pi).abs();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale,
                child: Icon(Icons.star_rounded, size: 14, color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
