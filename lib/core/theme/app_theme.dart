import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized theme configuration for Tripromio.
/// Provides both light and dark [ThemeData] built on top of [AppColors].
///
/// Typography uses **Nunito** via [google_fonts] — friendly, rounded, and
/// highly legible, which suits a social travel application well.
abstract final class AppTheme {
  // ── Text theme factory ────────────────────────────────────────────────────
  // google_fonts wraps each TextStyle with the Nunito font automatically.
  static TextTheme _textTheme(Color baseColor) =>
      GoogleFonts.nunitoTextTheme(TextTheme(
        displayLarge: TextStyle(
            fontSize: 57, fontWeight: FontWeight.w700, color: baseColor),
        displayMedium: TextStyle(
            fontSize: 45, fontWeight: FontWeight.w700, color: baseColor),
        displaySmall: TextStyle(
            fontSize: 36, fontWeight: FontWeight.w600, color: baseColor),
        headlineLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w700, color: baseColor),
        headlineMedium: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w600, color: baseColor),
        headlineSmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600, color: baseColor),
        titleLarge: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, color: baseColor),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: baseColor),
        titleSmall: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: baseColor),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, color: baseColor),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: baseColor),
        bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w400, color: baseColor),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: baseColor),
        labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: baseColor),
        labelSmall: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500, color: baseColor),
      ));

  // ── Shared button text styles ─────────────────────────────────────────────
  static TextStyle get _elevatedBtnText =>
      GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle get _textBtnText =>
      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle get _appBarTitleLight => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
      );

  static TextStyle get _appBarTitleDark => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
      );

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryLight,
          onPrimaryContainer: Colors.white,
          secondary: AppColors.accent,
          onSecondary: Colors.white,
          surface: AppColors.surfaceLight,
          onSurface: AppColors.textPrimaryLight,
          error: AppColors.error,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        cardTheme: const CardThemeData(
          color: AppColors.cardLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: AppColors.borderLight),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surfaceLight,
          foregroundColor: AppColors.textPrimaryLight,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: _appBarTitleLight,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundLight,
          hintStyle: GoogleFonts.nunito(
            fontSize: 14,
            color: AppColors.textHintLight,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: _elevatedBtnText,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: _textBtnText,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderLight,
          thickness: 1,
          space: 1,
        ),
        textTheme: _textTheme(AppColors.textPrimaryLight),
      );

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryDark,
          onPrimaryContainer: Colors.white,
          secondary: AppColors.accent,
          onSecondary: Colors.white,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textPrimaryDark,
          error: AppColors.error,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        cardTheme: const CardThemeData(
          color: AppColors.cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: AppColors.borderDark),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: _appBarTitleDark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardDark,
          hintStyle: GoogleFonts.nunito(
            fontSize: 14,
            color: AppColors.textHintDark,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: _elevatedBtnText,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            textStyle: _textBtnText,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderDark,
          thickness: 1,
          space: 1,
        ),
        textTheme: _textTheme(AppColors.textPrimaryDark),
      );
}
