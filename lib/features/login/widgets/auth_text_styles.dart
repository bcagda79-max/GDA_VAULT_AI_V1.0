import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens for auth screens using Inter font.
class AuthTextStyles {
  AuthTextStyles._();

  static String? _fontFamily;
  static String get _family {
    _fontFamily ??= GoogleFonts.inter().fontFamily;
    return _fontFamily!;
  }

  /// "GDA Vault AI" — 28sp, w700, letterSpacing -0.5
  static TextStyle displayTitle({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color,
      );

  /// "GALIYAT DEVELOPMENT AUTHORITY" — 11sp, w500, uppercase, letterSpacing 2.0
  static TextStyle subtitle({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.0,
        color: color,
      );

  /// Card title — 24sp, w600
  static TextStyle cardTitle({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Card subtitle / body — 14sp, w400
  static TextStyle cardSubtitle({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  /// Field labels — 11sp, w500, uppercase, letterSpacing 0.3
  static TextStyle label({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: color,
      );

  /// Body text — 14sp, w400
  static TextStyle body({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// Button text — 15sp, w600, letterSpacing 0.3
  static TextStyle button({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: color,
      );

  /// Feature title — 14sp, w500
  static TextStyle featureTitle({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// Feature subtitle — 12sp, w400
  static TextStyle featureSubtitle({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color,
      );

  /// Input text — 14sp, w400
  static TextStyle input({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// Error text — 12sp, w400
  static TextStyle error({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// Link text — 14sp, w600
  static TextStyle link({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Copyright — 11sp, w400
  static TextStyle copyright({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// Forgot password link — 13sp, w500
  static TextStyle forgotPassword({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      );
}
