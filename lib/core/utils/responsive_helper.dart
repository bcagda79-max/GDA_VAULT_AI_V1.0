import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 900;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > 600 &&
      MediaQuery.of(context).size.width <= 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= 600;

  static double sidebarWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 280;
    if (width > 1100) return 260;
    return 240;
  }

  static double contentPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 40;
    if (width > 1100) return 32;
    return 24;
  }
}
