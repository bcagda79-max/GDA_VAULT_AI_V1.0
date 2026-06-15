// lib/widgets/gda_status_chip.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class GdaStatusChip extends StatelessWidget {
  final String label;
  final Color statusColor;

  const GdaStatusChip({
    super.key,
    required this.label,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgSurface = isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight = isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final shadowXs = isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowXs;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(color: borderLight, width: 1.0),
        boxShadow: shadowXs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }
}
