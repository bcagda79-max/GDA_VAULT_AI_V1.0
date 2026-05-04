// lib/core/theme/light_theme.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

/// The light theme for the application.
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.primaryBlue,
  scaffoldBackgroundColor: AppColors.lightBg,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primaryBlue,
    foregroundColor: Colors.white,
    elevation: 8,
    shadowColor: AppColors.primaryBlue.withValues(alpha: 0.2),
    titleTextStyle: AppTextStyles.titleLarge.copyWith(color: Colors.white),
  ),
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryBlue,
    secondary: AppColors.goldLightBrand,
    surface: AppColors.white,
    error: Colors.red,
    onPrimary: Colors.white,
    onSecondary: AppColors.lightText,
    onSurface: AppColors.lightText,
    onError: Colors.white,
  ),
  cardTheme: CardThemeData(
    color: AppColors.white,
    elevation: 3,
    shadowColor: AppColors.primaryBlue.withValues(alpha: 0.08),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      textStyle: AppTextStyles.titleMedium,
    ),
  ),
  textTheme: TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppColors.lightText),
    titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.lightText),
    titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.lightText),
    bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.lightText),
    bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.lightText),
    labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.lightText),
  ),
);
