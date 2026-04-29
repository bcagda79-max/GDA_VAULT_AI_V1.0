// lib/core/constants/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Defines the text styles for the GDA Vault AI application.
class AppTextStyles {
  static final TextStyle playfairDisplay = GoogleFonts.playfairDisplay();
  static final TextStyle dmSans = GoogleFonts.dmSans();

  static final TextStyle displayLarge = GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.charcoal,
  );

  static final TextStyle headlineMedium = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle titleLarge = GoogleFonts.playfairDisplay(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle titleMedium = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static final TextStyle bodySmall = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  static final TextStyle labelSmall = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Special text style for dark theme
  static final TextStyle displayLargeDark = displayLarge.copyWith(
    color: AppColors.darkText,
  );

  // Simple clean number style — DM Sans only, no Playfair
  static TextStyle statNumber = GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.charcoal,
  );

  static TextStyle statNumberDark = GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.darkText,
  );
}
