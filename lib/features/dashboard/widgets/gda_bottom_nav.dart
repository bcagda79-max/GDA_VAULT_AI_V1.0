// lib/features/dashboard/widgets/gda_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

/// The custom bottom navigation bar for the dashboard.
class GdaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GdaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.navyDark,
        border: Border(
          top: BorderSide(color: AppColors.gold.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, "Home"),
          _buildNavItem(1, Icons.document_scanner, "Scan"),
          _buildNavItem(2, Icons.smart_toy_rounded, "AI Chat"),
          _buildNavItem(3, Icons.settings_rounded, "Settings"),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = currentIndex == index;
    final color = isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70, // Min tap area
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator line on top
            AnimatedContainer(
              height: 2.5,
              width: isSelected ? 24 : 0,
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
