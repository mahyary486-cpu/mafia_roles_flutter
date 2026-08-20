import 'package:flutter/material.dart';

/// Bilingual text styles used everywhere a role/UI name is shown in both
/// languages: a bold white "flashy" style for English, and a gold,
/// book-style (serif) style for Persian.
///
/// These use Android's built-in font families only (no network fonts),
/// so the app stays fully offline.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle englishFlashy = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 18,
    letterSpacing: 0.5,
    shadows: [
      Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
    ],
  );

  static const TextStyle persianGold = TextStyle(
    color: Color(0xFFFFF59D),
    fontFamily: 'serif',
    fontWeight: FontWeight.w600,
    fontSize: 11,
  );
}
