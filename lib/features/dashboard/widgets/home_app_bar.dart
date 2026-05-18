// lib/features/dashboard/widgets/home_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/utils/responsive_app_bar.dart';
import 'package:gda_vault_ai/providers/theme_provider.dart';

/// The custom AppBar for the main dashboard screen.
class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final int currentIndex;

  final bool isDesktop;

  /// Optional left inset to align appbar content when a permanent
  /// desktop navigation panel is present.
  final double leftInset;

  const HomeAppBar({
    super.key,
    required this.currentIndex,
    this.leftInset = 0,
    this.isDesktop = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    isDesktop ? ResponsiveAppBar.desktopHeight : ResponsiveAppBar.mobileHeight,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      foregroundColor: Colors.white,
      scrolledUnderElevation: 0,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkBg]
                : [AppColors.navyDark, AppColors.navyMid],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: isDesktop
                ? ResponsiveAppBar.desktopPadding
                : ResponsiveAppBar.mobilePadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'DASHBOARD',
                          style: AppTextStyles.playfairDisplay.copyWith(
                            fontSize: isDesktop ? 20 : 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Galiyat Development Authority',
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: isDesktop ? 10 : 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.5),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
