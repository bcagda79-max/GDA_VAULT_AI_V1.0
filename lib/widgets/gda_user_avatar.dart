// lib/widgets/gda_user_avatar.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';

class GdaUserAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const GdaUserAvatar({
    super.key,
    required this.initials,
    this.size = 34.0,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 13.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = backgroundColor ?? (isDark ? AppTokens.darkBrandSurface : AppTokens.lightBrandSurface);
    final text = textColor ?? (isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: text,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
