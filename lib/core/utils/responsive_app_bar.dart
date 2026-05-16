import 'package:flutter/material.dart';

class ResponsiveAppBar {
  static const double desktopBreakpoint = 900;
  static const double mobileHeight = 56;
  static const double desktopHeight = 76;
  static const EdgeInsets mobilePadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 4,
  );
  static const EdgeInsets desktopPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 10,
  );

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }

  static double height(BuildContext context) {
    return isDesktop(context) ? desktopHeight : mobileHeight;
  }

  static EdgeInsets padding(BuildContext context) {
    return isDesktop(context) ? desktopPadding : mobilePadding;
  }

  static double titleFontSize(BuildContext context) {
    return isDesktop(context) ? 22 : 16;
  }

  static double subtitleFontSize(BuildContext context) {
    return isDesktop(context) ? 11 : 8;
  }
}
