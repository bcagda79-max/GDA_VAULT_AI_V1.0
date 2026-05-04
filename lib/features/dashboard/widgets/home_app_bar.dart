// lib/features/dashboard/widgets/home_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/providers/theme_provider.dart';

/// The custom AppBar for the main dashboard screen.
class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final int currentIndex;
  const HomeAppBar({super.key, required this.currentIndex});

  @override
  Size get preferredSize => const Size.fromHeight(76.0);

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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LEFT GROUP: Logo + Text
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/images/gda_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            "GDA",
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).scale(delay: 100.ms),
                    const SizedBox(width: 14),
                    Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "GDA VAULT AI",
                              style: AppTextStyles.playfairDisplay.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.gold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              "Galiyat Development Authority",
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.6),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .slideX(begin: -0.1, end: 0),
                  ],
                ),
                // Theme toggle removed as requested
              ],
            ),
          ),
        ),
      ),
    );
  }
}
