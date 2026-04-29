// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

/// Centralized theme management for the application.
class AppTheme {
  static ThemeData get light => lightTheme;
  static ThemeData get dark => darkTheme;
}
