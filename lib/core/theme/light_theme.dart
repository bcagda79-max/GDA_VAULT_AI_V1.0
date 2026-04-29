// lib/core/theme/light_theme.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

/// The light theme for the application.
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.navyDark,
  scaffoldBackgroundColor: AppColors.paper,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.navyDark,
    foregroundColor: AppColors.white,
    elevation: 8,
    shadowColor: AppColors.navyDark.withOpacity(0.2),
    titleTextStyle: AppTextStyles.titleLarge.copyWith(color: AppColors.white),
  ),
  colorScheme: const ColorScheme.light(
    primary: AppColors.navyDark,
    secondary: AppColors.gold,
    surface: AppColors.white,
    background: AppColors.paper,
    error: Colors.red,
    onPrimary: AppColors.white,
    onSecondary: AppColors.charcoal,
    onSurface: AppColors.charcoal,
    onBackground: AppColors.charcoal,
    onError: AppColors.white,
  ),
  cardTheme: CardThemeData(
    color: AppColors.white,
    elevation: 3,
    shadowColor: AppColors.navyDark.withOpacity(0.08),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.navyDark,
      foregroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      textStyle: AppTextStyles.titleMedium,
    ),
  ),
  textTheme: TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    headlineMedium: AppTextStyles.headlineMedium,
    titleLarge: AppTextStyles.titleLarge,
    titleMedium: AppTextStyles.titleMedium,
    bodyLarge: AppTextStyles.bodyLarge,
    bodySmall: AppTextStyles.bodySmall,
    labelSmall: AppTextStyles.labelSmall,
  ),
);
