// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

/// Defines the color palette for the GDA Vault AI application.
class AppColors {
  // Primary Palette (from GDA logo + DocVault spec)
  static const Color navyDark = Color(0xFF0D1B3E); // primary brand
  static const Color navyMid = Color(0xFF1A2F5E); // nav bar
  static const Color navyLight = Color(0xFF1A3A6B); // cards light
  static const Color gdaGreen = Color(0xFF1A6B3A); // GDA logo green
  static const Color gdaGreenMid = Color(0xFF27AE60); // accent green
  static const Color gold = Color(0xFFC9A84C); // active/highlight
  static const Color gdaGold = gold; // Alias for gold used in several screens
  static const Color goldLight = Color(0xFFE6C76A); // hover gold

  // Neutrals
  static const Color paper = Color(0xFFF5F2EB); // light background
  static const Color charcoal = Color(0xFF1C1C2E); // primary text
  static const Color slate = Color(0xFFE8EAF2); // secondary surface
  static const Color white = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFDDE1EC);

  // Dark Mode
  static const Color darkBg = Color(0xFF0A0F1E);
  static const Color darkSurface = Color(0xFF1A2240);
  static const Color darkCard = Color(0xFF1E2A4A);
  static const Color darkText = Color(0xFFE8EAF2);

  // Category Colors (5 categories)
  static const Color catBoard = Color(0xFF1A3A6B); // Board of Authority
  static const Color catTrust = Color(0xFF1A6B3A); // Trust Minutes
  static const Color catTown = Color(0xFF8B4513); // Town/Plots
  static const Color catAdmin = Color(0xFF4A1A6B); // Administration
  static const Color catPrivate = Color(0xFF6B1A1A); // Private Properties
}
