// lib/core/constants/app_spacing.dart
import 'package:flutter/material.dart';

/// Defines consistent spacing values for the application.
class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);

  static const EdgeInsets symetricHorizontalMd = EdgeInsets.symmetric(
    horizontal: md,
  );
  static const EdgeInsets symetricVerticalMd = EdgeInsets.symmetric(
    vertical: md,
  );

  /// Returns a horizontal spacing of the given width.
  static SizedBox horizontal(double width) => SizedBox(width: width);

  /// Returns a vertical spacing of the given height.
  static SizedBox vertical(double height) => SizedBox(height: height);
}
