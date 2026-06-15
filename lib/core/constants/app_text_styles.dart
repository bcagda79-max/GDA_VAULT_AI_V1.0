import 'package:flutter/material.dart';

/// Enterprise Typography System
/// Font family: Inter (applied via GoogleFonts in ThemeData)
class AppTextStyles {
  static const TextStyle displayLg = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMd = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle displaySm = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.4,
  );

  static const TextStyle headingLg = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.4,
  );

  static const TextStyle headingMd = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.5,
  );

  static const TextStyle headingSm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.5,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.6,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.6,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static const TextStyle labelLg = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle labelMd = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    height: 1.3, // Typically used with uppercase
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
  );
}
