import 'package:flutter/material.dart';

/// Enterprise Design System Tokens
class AppTokens {
  // LIGHT MODE ──────────────────────────────────────────
  
  // Backgrounds
  static const Color lightBgPage = Color(0xFFF5F5F5);
  static const Color lightBgSurface = Color(0xFFFFFFFF);
  static const Color lightBgSidebar = Color(0xFF111111);
  static const Color lightBgTopBar = Color(0xFFFFFFFF);

  // Borders
  static const Color lightBorderLight = Color(0xFFE4E7EC);
  static const Color lightBorderMedium = Color(0xFFD0D5DD);

  // Text
  static const Color lightTextPrimary = Color(0xFF101828);
  static const Color lightTextSecondary = Color(0xFF475467);
  static const Color lightTextTertiary = Color(0xFF98A2B3);
  static const Color lightTextSidebar = Color(0xFF8899B0);
  static const Color lightTextSidebarActive = Color(0xFFFFFFFF);

  // Brand / Action
  static const Color lightBrandPrimary = Color(0xFF141414); // Sleek neutral dark
  static const Color lightBrandHover = Color(0xFF272727);
  static const Color lightBrandSurface = Color(0xFFF3F4F6);

  // Status
  static const Color lightStatusSuccess = Color(0xFF12B76A);
  static const Color lightStatusError = Color(0xFFF04438);
  static const Color lightStatusWarn = Color(0xFFF79009);

  // Shadows
  static const List<BoxShadow> lightShadowSm = [
    BoxShadow(color: Color(0x1A101828), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(color: Color(0x0F101828), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> lightShadowMd = [
    BoxShadow(color: Color(0x14101828), offset: Offset(0, 4), blurRadius: 8),
    BoxShadow(color: Color(0x0A101828), offset: Offset(0, 2), blurRadius: 4),
  ];
  static const List<BoxShadow> lightShadowXs = [
    BoxShadow(color: Color(0x0D101828), offset: Offset(0, 1), blurRadius: 2),
  ];

  // DARK MODE ───────────────────────────────────────────
  
  // Backgrounds
  static const Color darkBgPage = Color(0xFF0A0A0A);
  static const Color darkBgSurface = Color(0xFF141414);
  static const Color darkBgSurface2 = Color(0xFF1C1C1C);
  static const Color darkBgSidebar = Color(0xFF0A0A0A);
  static const Color darkBgTopBar = Color(0xFF141414);
  static const Color darkHeaderBg = Color(0xFF0A0A0A);
  static const Color darkInputFill = Color(0xFF111111);

  // Borders
  static const Color darkBorderLight = Color(0xFF272727);
  static const Color darkBorderMedium = Color(0xFF333333);

  // Text
  static const Color darkTextPrimary = Color(0xFFEBEBEB);
  static const Color darkTextSecondary = Color(0xFF8A8A8A);
  static const Color darkTextTertiary = Color(0xFF555555);
  static const Color darkTextSidebar = Color(0xFF64748B);
  static const Color darkTextSidebarActive = Color(0xFFFFFFFF);

  // Brand / Action
  static const Color darkBrandPrimary = Color(0xFFEBEBEB); // Soft white for dark mode
  static const Color darkBrandHover = Color(0xFFFFFFFF);
  static const Color darkBrandSurface = Color(0xFF272727);

  // Status
  static const Color darkStatusSuccess = Color(0xFF32D583);
  static const Color darkStatusError = Color(0xFFF97066);
  static const Color darkStatusWarn = Color(0xFFF79009); // Added for consistency

  // Shadows
  static const List<BoxShadow> darkShadowSm = [
    BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 3),
  ];
  static const List<BoxShadow> darkShadowMd = [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 4), blurRadius: 8),
  ];
  static const List<BoxShadow> darkShadowXs = [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  // SPACING (8px grid) ──────────────────────────────────
  static const double sp4 = 4.0;
  static const double sp8 = 8.0;
  static const double sp12 = 12.0;
  static const double sp16 = 16.0;
  static const double sp20 = 20.0;
  static const double sp24 = 24.0;
  static const double sp32 = 32.0;
  static const double sp40 = 40.0;
  static const double sp48 = 48.0;

  // BORDER RADIUS ───────────────────────────────────────
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusFull = 999.0;
}
