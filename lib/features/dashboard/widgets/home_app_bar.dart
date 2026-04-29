// lib/features/dashboard/widgets/home_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/providers/theme_provider.dart';

/// The custom AppBar for the main dashboard screen.
class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final int currentIndex;
  const HomeAppBar({super.key, required this.currentIndex});

  @override
  Size get preferredSize => const Size.fromHeight(62.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.navyDark,
      elevation: 0,
      flexibleSpace: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.gold.withOpacity(0.25),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LEFT GROUP
              Row(
                children: [
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: Image.asset(
                      'assets/images/gda_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          "GDA",
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "GDA Vault AI",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        "Galiyat Development Authority",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 9,
                          color: Colors.white.withOpacity(0.55),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // RIGHT GROUP
              GestureDetector(
                onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
