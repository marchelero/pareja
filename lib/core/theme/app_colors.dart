import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFFF2D78);
  static const Color primaryGradient = Color(0xFFFF6B35);
  static const Color accent = Color(0xFFB44AFF);

  static const Color primaryNeon = Color(0xFFFF2D78);
  static const Color secondaryNeon = Color(0xFFFF6B35);
  static const Color tertiaryPurple = Color(0xFFB44AFF);

  static const Color backgroundDark = Colors.black;
  static const Color backgroundSecondary = Color(0xFF0D0020);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color surfacePurple = Color(0xFF1A0A2E);

  static const Color playerHe = Colors.blueAccent;
  static const Color playerShe = Colors.pinkAccent;

  static const Color modeQuestions = Color(0xFFFF9800);
  static const Color modeRoulette = Color(0xFF2196F3);
  static const Color modeDrinks = Color(0xFF8B0000);
  static const Color modeBomb = Color(0xFFFF5722);
  static const Color modeMostLikely = Color(0xFF009688);
  static const Color modeCharades = Color(0xFF673AB7);

  static Color glassBackground(double opacity) => Colors.white.withValues(alpha: opacity);
  static Color glassBorder(double opacity) => Colors.white.withValues(alpha: opacity);

  static const Color scoreWin = Colors.greenAccent;
  static const Color scoreLose = Colors.redAccent;
  static const Color scoreTie = Colors.orange;

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textHint = Color(0x80FFFFFF);

  static const List<Color> primaryGradientColors = [primaryNeon, secondaryNeon];
  static const List<Color> backgroundGradient = [
    Color(0xFF0D0020),
    Color(0xFF1A0030),
    Colors.black,
  ];
}
