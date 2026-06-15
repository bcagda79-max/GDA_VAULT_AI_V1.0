// lib/core/theme/light_theme.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';

/// The light theme for the application using new Enterprise Design Tokens.
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppTokens.lightBrandPrimary,
  scaffoldBackgroundColor: AppTokens.lightBgPage,
  appBarTheme: AppBarTheme(
    backgroundColor: AppTokens.lightBgTopBar,
    foregroundColor: AppTokens.lightTextPrimary,
    elevation: 0,
    shadowColor: Colors.transparent,
    titleTextStyle: AppTextStyles.headingMd.copyWith(color: AppTokens.lightTextPrimary),
  ),
  colorScheme: const ColorScheme.light(
    primary: AppTokens.lightBrandPrimary,
    secondary: AppTokens.lightBrandSurface,
    surface: AppTokens.lightBgSurface,
    error: AppTokens.lightStatusError,
    onPrimary: Colors.white,
    onSecondary: AppTokens.lightTextPrimary,
    onSurface: AppTokens.lightTextPrimary,
    onError: Colors.white,
  ),
  cardTheme: CardThemeData(
    color: AppTokens.lightBgSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      side: const BorderSide(color: AppTokens.lightBorderLight),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTokens.lightBrandPrimary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
      textStyle: AppTextStyles.labelLg.copyWith(color: Colors.white),
      elevation: 0,
    ),
  ),
  textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
    displayLarge: AppTextStyles.displayLg.copyWith(color: AppTokens.lightTextPrimary),
    displayMedium: AppTextStyles.displayMd.copyWith(color: AppTokens.lightTextPrimary),
    displaySmall: AppTextStyles.displaySm.copyWith(color: AppTokens.lightTextPrimary),
    headlineMedium: AppTextStyles.headingMd.copyWith(color: AppTokens.lightTextPrimary),
    headlineSmall: AppTextStyles.headingSm.copyWith(color: AppTokens.lightTextPrimary),
    titleLarge: AppTextStyles.headingMd.copyWith(color: AppTokens.lightTextPrimary),
    titleMedium: AppTextStyles.headingSm.copyWith(color: AppTokens.lightTextPrimary),
    bodyLarge: AppTextStyles.bodyLg.copyWith(color: AppTokens.lightTextPrimary),
    bodyMedium: AppTextStyles.bodyMd.copyWith(color: AppTokens.lightTextPrimary),
    bodySmall: AppTextStyles.bodySm.copyWith(color: AppTokens.lightTextPrimary),
    labelLarge: AppTextStyles.labelLg.copyWith(color: AppTokens.lightTextPrimary),
    labelMedium: AppTextStyles.labelMd.copyWith(color: AppTokens.lightTextPrimary),
    labelSmall: AppTextStyles.labelSm.copyWith(color: AppTokens.lightTextPrimary),
  ),
  iconTheme: const IconThemeData(color: AppTokens.lightTextSecondary),
);
