import 'package:flutter/material.dart';

/// Dedicated color palette for authentication screens.
/// All hex values match the enterprise design system spec.
class AuthColors {
  AuthColors._();

  // ── Light Mode ──
  static const Color lightPrimary = Color(0xFF1A3A5C);
  static const Color lightPrimaryLight = Color(0xFF2563EB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF4F6F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextHint = Color(0xFF94A3B8);
  static const Color lightInputFill = Color(0xFFF8FAFC);

  // ── Dark Mode ──
  static const Color darkPrimary = Color(0xFF1E3A5F);
  static const Color darkPrimaryLight = Color(0xFF3B82F6);
  static const Color darkSurface = Color(0xFF141414);
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkTextPrimary = Color(0xFFEBEBEB);
  static const Color darkTextSecondary = Color(0xFF8A8A8A);
  static const Color darkTextHint = Color(0xFF555555);
  static const Color darkInputFill = Color(0xFF111111);

  // ── Shared ──
  static const Color leftPanelBg = Color(0xFF0A0A0A);
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color strengthWeak = Color(0xFFDC2626);
  static const Color strengthMedium = Color(0xFFF59E0B);
  static const Color strengthStrong = Color(0xFF16A34A);
  static const Color actionBlue = Color(0xFF2563EB);
  static const Color actionBlueHover = Color(0xFF1D4ED8);
  static const Color featureIconBg = Color(0xFF1E3A5F);
  static const Color featureIconColor = Color(0xFF3B82F6);
  static const Color chipBg = Color(0xFFEFF6FF);
  static const Color chipText = Color(0xFF1D4ED8);

  /// Build a light-mode ThemeData for auth screens.
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: lightPrimaryLight,
        onPrimary: Colors.white,
        secondary: lightPrimary,
        onSecondary: Colors.white,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        error: error,
        onError: Colors.white,
        outline: lightBorder,
        surfaceContainerHighest: lightInputFill,
      ),
    );
  }

  /// Build a dark-mode ThemeData for auth screens.
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimaryLight,
        onPrimary: Colors.white,
        secondary: darkPrimary,
        onSecondary: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        error: error,
        onError: Colors.white,
        outline: darkBorder,
        surfaceContainerHighest: darkInputFill,
      ),
    );
  }
}
