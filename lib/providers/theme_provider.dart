import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeMode build() {
    return ThemeMode.light;
  }

  bool get isDark => state == ThemeMode.dark;

  void toggleTheme() {
    state = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}
