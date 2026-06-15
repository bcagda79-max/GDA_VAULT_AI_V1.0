// lib/widgets/gda_browse_item.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class GdaBrowseItem extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const GdaBrowseItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<GdaBrowseItem> createState() => _GdaBrowseItemState();
}

class _GdaBrowseItemState extends State<GdaBrowseItem> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) => setState(() => _isPressed = true);
  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }
  void _handleTapCancel() => setState(() => _isPressed = false);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgSurface = isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight = isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final brandPrimary = isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;
    final brandSurface = isDark ? AppTokens.darkBrandSurface : AppTokens.lightBrandSurface;
    final textPrimary = isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary = isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final shadowXs = isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowXs;

    final scale = _isPressed ? 0.98 : 1.0;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            border: Border.all(color: borderLight, width: 1.0),
            boxShadow: shadowXs,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: brandSurface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: brandPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTextStyles.headingSm.copyWith(color: textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: AppTextStyles.bodySm.copyWith(color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
