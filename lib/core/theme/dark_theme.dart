// lib/core/theme/dark_theme.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';

/// The dark theme for the application using new Enterprise Design Tokens.
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppTokens.darkBrandPrimary,
  scaffoldBackgroundColor: AppTokens.darkBgPage,
  appBarTheme: AppBarTheme(
    backgroundColor: AppTokens.darkBgTopBar,
    foregroundColor: AppTokens.darkTextPrimary,
    elevation: 0,
    shadowColor: Colors.transparent,
    titleTextStyle: AppTextStyles.headingMd.copyWith(color: AppTokens.darkTextPrimary),
  ),
  colorScheme: const ColorScheme.dark(
    primary: AppTokens.darkBrandPrimary,
    secondary: AppTokens.darkBrandSurface,
    surface: AppTokens.darkBgSurface,
    error: AppTokens.darkStatusError,
    onPrimary: Colors.white,
    onSecondary: AppTokens.darkTextPrimary,
    onSurface: AppTokens.darkTextPrimary,
    onError: Colors.white,
  ),
  cardTheme: CardThemeData(
    color: AppTokens.darkBgSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      side: const BorderSide(color: AppTokens.darkBorderLight),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTokens.darkBrandPrimary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
      textStyle: AppTextStyles.labelLg.copyWith(color: Colors.white),
      elevation: 0,
    ),
  ),
  textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
    displayLarge: AppTextStyles.displayLg.copyWith(color: AppTokens.darkTextPrimary),
    displayMedium: AppTextStyles.displayMd.copyWith(color: AppTokens.darkTextPrimary),
    displaySmall: AppTextStyles.displaySm.copyWith(color: AppTokens.darkTextPrimary),
    headlineMedium: AppTextStyles.headingMd.copyWith(color: AppTokens.darkTextPrimary),
    headlineSmall: AppTextStyles.headingSm.copyWith(color: AppTokens.darkTextPrimary),
    titleLarge: AppTextStyles.headingMd.copyWith(color: AppTokens.darkTextPrimary),
    titleMedium: AppTextStyles.headingSm.copyWith(color: AppTokens.darkTextPrimary),
    bodyLarge: AppTextStyles.bodyLg.copyWith(color: AppTokens.darkTextPrimary),
    bodyMedium: AppTextStyles.bodyMd.copyWith(color: AppTokens.darkTextPrimary),
    bodySmall: AppTextStyles.bodySm.copyWith(color: AppTokens.darkTextPrimary),
    labelLarge: AppTextStyles.labelLg.copyWith(color: AppTokens.darkTextPrimary),
    labelMedium: AppTextStyles.labelMd.copyWith(color: AppTokens.darkTextPrimary),
    labelSmall: AppTextStyles.labelSm.copyWith(color: AppTokens.darkTextPrimary),
  ),
  iconTheme: const IconThemeData(color: AppTokens.darkTextSecondary),
);
