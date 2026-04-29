// lib/core/theme/dark_theme.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

/// The dark theme for the application.
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.navyMid,
  scaffoldBackgroundColor: AppColors.darkBg,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.darkText,
    elevation: 0,
    titleTextStyle: AppTextStyles.titleLarge.copyWith(
      color: AppColors.darkText,
    ),
  ),
  colorScheme: const ColorScheme.dark(
    primary: AppColors.navyMid,
    secondary: AppColors.gold,
    surface: AppColors.darkSurface,
    error: Colors.redAccent,
    onPrimary: AppColors.darkText,
    onSecondary: AppColors.darkText,
    onSurface: AppColors.darkText,
    onError: AppColors.darkText,
  ),
  cardTheme: CardThemeData(
    color: AppColors.darkCard,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.navyMid,
      foregroundColor: AppColors.darkText,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      textStyle: AppTextStyles.titleMedium.copyWith(color: AppColors.darkText),
    ),
  ),
  textTheme: TextTheme(
    displayLarge: AppTextStyles.displayLargeDark,
    headlineMedium: AppTextStyles.headlineMedium.copyWith(
      color: AppColors.darkText,
    ),
    titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.darkText),
    titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.darkText),
    bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.darkText),
    bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.darkText),
    labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.darkText),
  ),
);
