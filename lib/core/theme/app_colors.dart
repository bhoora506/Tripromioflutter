import 'package:flutter/material.dart';

/// Centralized color palette for Tripromio.
/// All colors used across the app must be referenced from here.
abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0066FF);       // Vibrant blue
  static const Color primaryDark = Color(0xFF0047CC);   // Deeper blue for pressed states
  static const Color primaryLight = Color(0xFF4D94FF);  // Lighter variant
  static const Color accent = Color(0xFFFF6B35);        // Warm coral — travel energy

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF0D1117);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF161B22);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1C2128);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF0D1117);
  static const Color textPrimaryDark = Color(0xFFE6EDF3);
  static const Color textSecondaryLight = Color(0xFF57606A);
  static const Color textSecondaryDark = Color(0xFF8B949E);
  static const Color textHintLight = Color(0xFFB1BAC4);
  static const Color textHintDark = Color(0xFF484F58);

  // ── Borders & Dividers ───────────────────────────────────────────────────
  static const Color borderLight = Color(0xFFD0D7DE);
  static const Color borderDark = Color(0xFF30363D);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2DA44E);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFCF222E);
  static const Color info = Color(0xFF0969DA);

  // ── Gradient stops ───────────────────────────────────────────────────────
  static const List<Color> primaryGradient = [
    Color(0xFF0066FF),
    Color(0xFF00C6FF),
  ];

  static const List<Color> heroGradient = [
    Color(0xFF0066FF),
    Color(0xFFFF6B35),
  ];
}
