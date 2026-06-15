// lib/widgets/gda_stat_card.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class GdaStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const GdaStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgSurface = isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight = isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final textTertiary = isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final textPrimary = isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary;
    final brandPrimary = isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;
    final shadowXs = isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowXs;

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp20),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: borderLight, width: 1.0),
        boxShadow: shadowXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 10,
                    color: textTertiary,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: textTertiary,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.sp12),
          Text(
            value,
            style: AppTextStyles.displayMd.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: AppTokens.sp12),
          Container(
            height: 2,
            width: 32,
            decoration: BoxDecoration(
              color: brandPrimary,
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            ),
          ),
        ],
      ),
    );
  }
}
