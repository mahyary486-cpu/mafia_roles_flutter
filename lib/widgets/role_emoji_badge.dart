import 'package:flutter/material.dart';

/// A role's emoji, shown with a soft colored halo behind it indicating
/// which side (mafia/citizen/independent) the role belongs to.
class RoleEmojiBadge extends StatelessWidget {
  final String emoji;
  final Color color;
  final double size;

  const RoleEmojiBadge({
    super.key,
    required this.emoji,
    required this.color,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.28),
        border: Border.all(color: color.withOpacity(0.8), width: 1.2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.7), blurRadius: size * 0.4),
        ],
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.6)),
    );
  }
}
