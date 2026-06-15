// lib/widgets/gda_quick_action_card.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class GdaQuickActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const GdaQuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<GdaQuickActionCard> createState() => _GdaQuickActionCardState();
}

class _GdaQuickActionCardState extends State<GdaQuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgSurface = isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight = isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final borderMedium = isDark ? AppTokens.darkBorderMedium : AppTokens.lightBorderMedium;
    final brandPrimary = isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;
    final textPrimary = isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary = isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final shadowXs = isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowXs;
    final shadowSm = isDark ? AppTokens.darkShadowSm : AppTokens.lightShadowSm;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            border: Border.all(
              color: _isHovered ? borderMedium : borderLight,
            ),
            boxShadow: _isHovered ? shadowSm : shadowXs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(widget.icon, size: 20, color: brandPrimary),
                  Icon(Icons.arrow_forward, size: 14, color: textTertiary),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: AppTextStyles.headingSm.copyWith(color: textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: AppTextStyles.bodySm.copyWith(color: textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
