// lib/core/theme/dark_theme.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

/// The dark theme for the application.
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primaryBlue,
  scaffoldBackgroundColor: AppColors.darkBg,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.darkCard,
    foregroundColor: AppColors.darkTextPrimary,
    elevation: 0,
    titleTextStyle: AppTextStyles.titleLarge.copyWith(
      color: AppColors.darkTextPrimary,
    ),
  ),
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryBlue,
    secondary: AppColors.goldDark,
    surface: AppColors.darkCard,
    error: Colors.redAccent,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.darkTextPrimary,
    onError: Colors.white,
  ),
  cardTheme: CardThemeData(
    color: AppColors.darkCard,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      textStyle: AppTextStyles.titleMedium.copyWith(color: Colors.white),
    ),
  ),
  textTheme: TextTheme(
    displayLarge: AppTextStyles.displayLargeDark,
    headlineMedium: AppTextStyles.headlineMedium.copyWith(
      color: AppColors.darkTextPrimary,
    ),
    titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.darkTextPrimary),
    titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.darkTextPrimary),
    bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.darkTextPrimary),
    bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.darkTextPrimary),
    labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.darkTextPrimary),
  ),
  iconTheme: const IconThemeData(color: AppColors.darkIcon),
);
