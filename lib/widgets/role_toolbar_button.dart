import 'package:flutter/material.dart';

import '../models/role.dart';

/// A single role button for the Day/Night action toolbars: one icon plus
/// the role's name underneath - the same look everywhere, so a role
/// always reads the same way whether it's on the Full Roster, Day, or
/// Night screen (rather than two different icon styles for the same
/// role, one per screen).
///
/// Pulses (blinks) while [armed] is true, so it's obvious the game
/// master still needs to tap a player to finish the action - and stops
/// the instant it's tapped again or a target is chosen.
class RoleToolbarButton extends StatefulWidget {
  final Role role;
  final bool armed;
  final bool disabled;
  final VoidCallback? onTap;
  final Color surfaceColor;
  final Color labelColor;
  final Color borderColor;

  const RoleToolbarButton({
    super.key,
    required this.role,
    required this.armed,
    required this.disabled,
    required this.onTap,
    this.surfaceColor = const Color(0xFF2A2438),
    this.labelColor = Colors.white,
    this.borderColor = Colors.white24,
  });

  @override
  State<RoleToolbarButton> createState() => _RoleToolbarButtonState();
}

class _RoleToolbarButtonState extends State<RoleToolbarButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.armed) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant RoleToolbarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.armed && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.armed) {
      _controller.stop();
      _controller.value = 0;
    }
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
      builder: (context, child) {
        final pulse = widget.armed ? _controller.value : 0.0;
        return GestureDetector(
          onTap: widget.disabled ? null : widget.onTap,
          child: Opacity(
            opacity: widget.disabled ? 0.35 : 1.0,
            child: Container(
              width: 64,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: widget.armed
                    ? widget.role.color.withOpacity(0.25 + pulse * 0.25)
                    : widget.surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.armed
                      ? Color.lerp(widget.role.color, Colors.white, pulse * 0.7)!
                      : widget.borderColor,
                  width: widget.armed ? 2.5 : 1,
                ),
                boxShadow: widget.armed
                    ? [
                        BoxShadow(
                          color: widget.role.color.withOpacity(0.4 + pulse * 0.5),
                          blurRadius: 6 + pulse * 10,
                          spreadRadius: 1 + pulse * 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.role.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 2),
                  Text(
                    widget.role.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: widget.armed ? widget.role.color : widget.labelColor,
                    ),
                  ),
                  if (widget.disabled)
                    Icon(Icons.block, size: 12, color: widget.labelColor.withOpacity(0.6)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
