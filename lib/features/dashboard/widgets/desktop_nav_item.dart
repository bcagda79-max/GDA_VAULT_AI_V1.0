import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class DesktopNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool showSeparator;
  const DesktopNavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.showSeparator = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.primaryBlue.withValues(alpha: 0.08)
        : Colors.transparent;
    final BorderSide? borderSide = selected
        ? BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.12))
        : null;

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: borderSide ?? BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                // left selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 6,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryBlue
                        : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryBlue : AppColors.paper,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? Colors.white
                        : AppColors.charcoal.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected
                          ? AppColors.charcoal
                          : AppColors.charcoal.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (showSeparator) {
      return Column(
        children: [
          content,
          const SizedBox(height: 6),
          Divider(height: 1, color: AppColors.navyDark.withValues(alpha: 0.06)),
        ],
      );
    }

    return content;
  }
}
