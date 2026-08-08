import 'package:flutter/material.dart';

/// Central place for every color used in the app.
class AppColors {
  AppColors._();

  // Base dark theme surfaces.
  static const Color background = Color(0xFF0E0E12);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2A2A2A);

  // Text.
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textGold = Color(0xFFFFEB3B);

  // Team colors.
  static const Color citizenTeam = Color(0xFF3B82F6); // blue
  static const Color mafiaTeam = Color(0xFFE53935); // red
  static const Color independentTeam = Color(0xFF9C27B0); // purple
  static const Color brightViolet = Color(0xFFC77DFF); // light violet for numbers

  // Accent used for buttons / selectable numbers.
  static const Color accent = Color(0xFF3B82F6);

  /// The 7 rotating neon colors used for the animated dot borders.
  static const List<Color> neonRainbow = [
    Color(0xFFFF3B3B), // red
    Color(0xFFFF9F1C), // orange
    Color(0xFFFFE93B), // yellow
    Color(0xFF3BFF6E), // green
    Color(0xFF3BD4FF), // cyan
    Color(0xFF3B6EFF), // blue
    Color(0xFFB93BFF), // violet
  ];
}
