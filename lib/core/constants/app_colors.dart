// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

/// Defines the color palette for the GDA Vault AI application.
class AppColors {
  // Brand Colors (Recommendations)
  static const Color primaryBlue = Color(0xFF1D4ED8); // Primary Button
  static const Color secondaryBlueDark = Color(
    0xFF1E3A5F,
  ); // Secondary Button (Dark)
  static const Color secondarySlate = Color(
    0xFF374151,
  ); // Secondary Button (Light)

  static const Color goldDark = Color(0xFFC9962A); // Header Badge (Dark)
  static const Color goldLightBrand = Color(0xFFB8860B); // Header Badge (Light)

  static const Color lightBg = Color(0xFFEEF2F7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF0F172A);

  // Neutrals - Dark Mode
  static const Color darkBg = Color(0xFF0B1120);
  static const Color darkCard = Color(0xFF141E30);
  static const Color darkTextPrimary = Color(0xFFE8EDF5);
  static const Color darkIcon = Color(0xFF60A5FA);

  // Legacy Aliases (to prevent breaking existing code)
  static const Color navyDark = Color(0xFF0B1120); // Mapped to darkBg
  static const Color navyMid = Color(0xFF141E30); // Mapped to darkCard
  static const Color navyLight = Color(
    0xFF1E3A5F,
  ); // Mapped to secondaryBlueDark
  static const Color gold = goldDark;
  static const Color gdaGold = goldDark;
  static const Color paper = lightBg;
  static const Color charcoal = lightText;
  static const Color darkText = darkTextPrimary;
  static const Color darkSurface = darkCard;
  static const Color divider = Color(0xFFDDE1EC);
  static const Color slate = secondarySlate;
  static const Color gdaGreen = primaryBlue;
  static const Color gdaGreenMid = primaryBlue;

  // Category Colors (Simplified or mapped to brand)
  static const Color catBoard = primaryBlue;
  static const Color catTrust = Color(0xFF1A6B3A);
  static const Color catTown = Color(0xFF8B4513);
  static const Color catAdmin = secondaryBlueDark;
  static const Color catPrivate = Color(0xFF6B1A1A);
}
