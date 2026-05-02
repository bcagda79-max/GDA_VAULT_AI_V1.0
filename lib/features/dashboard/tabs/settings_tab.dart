// lib/features/dashboard/tabs/settings_tab.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/providers/theme_provider.dart';
import 'package:gda_vault_ai/features/dashboard/providers/dashboard_stats_provider.dart';

/// The settings tab, allowing user to configure the app.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(
      themeProvider.select((mode) => mode == ThemeMode.dark),
    );
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Professional Centered Header Section (Sub-AppBar style)
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, isDark),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                statsAsync.when(
                  data: (stats) => _buildStorageCard(isDark, stats),
                  loading: () => _buildStorageCard(isDark, null, isLoading: true),
                  error: (_, __) => _buildStorageCard(isDark, null),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    "Preferences",
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: (isDark ? Colors.white : AppColors.navyDark).withValues(alpha: 0.5),
                    ),
                  ),
                ),
                _buildSettingsList(context, ref, isDark),
                const SizedBox(height: 40),
                _buildFooter(isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1D37), // Specific professional dark navy background
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          "Settings",
          style: AppTextStyles.playfairDisplay.copyWith(
            fontSize: 18, // Smaller font size
            fontWeight: FontWeight.bold,
            color: Colors.white, // Always white on navy background
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStorageCard(bool isDark, Map<String, dynamic>? stats, {bool isLoading = false}) {
    final double totalSizeGb = (stats?['total_size_gb'] as num?)?.toDouble() ?? 0.0;
    const double maxStorageGb = 100.0;
    final double percentage = (totalSizeGb / maxStorageGb).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: isDark ? 0.2 : 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: isDark ? 0.05 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_done_rounded,
                color: AppColors.gold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "GDA Cloud Storage",
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.navyDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                isLoading ? "..." : "${totalSizeGb.toStringAsFixed(1)} GB",
                style: AppTextStyles.dmSans.copyWith( // Simplified font
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.gold : AppColors.navyDark,
                ),
              ),
              Text(
                " / ${maxStorageGb.toInt()} GB used",
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 12,
                  color: (isDark ? Colors.white : AppColors.navyDark).withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isLoading ? "..." : "${(percentage * 100).toStringAsFixed(0)}%",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: isLoading ? null : percentage,
              backgroundColor: isDark ? AppColors.darkBg : AppColors.slate.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              minHeight: 8,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05);
  }

  Widget _buildSettingsList(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.dark_mode_outlined,
            iconBgColor: AppColors.gold.withValues(alpha: 0.1),
            iconColor: AppColors.gold,
            title: "Dark Mode Appearance",
            trailing: CupertinoSwitch(
              value: isDark,
              onChanged: (value) =>
                  ref.read(themeProvider.notifier).toggleTheme(),
              activeTrackColor: AppColors.gold,
            ),
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.folder_open_rounded,
            iconBgColor: AppColors.catBoard.withValues(alpha: 0.1),
            iconColor: AppColors.catBoard,
            title: "Manage Categories",
            trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.sync_problem_rounded,
            iconBgColor: AppColors.gdaGreen.withValues(alpha: 0.1),
            iconColor: AppColors.gdaGreen,
            title: "Sync Settings",
            trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.translate_rounded,
            iconBgColor: AppColors.catAdmin.withValues(alpha: 0.1),
            iconColor: AppColors.catAdmin,
            title: "Language preference",
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "English",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
              ],
            ),
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.help_outline_rounded,
            iconBgColor: isDark ? AppColors.darkSurface : AppColors.paper,
            iconColor: (isDark ? Colors.white : AppColors.navyDark).withValues(alpha: 0.6),
            title: "Help & Documentation",
            trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.logout_rounded,
            iconBgColor: AppColors.catPrivate.withValues(alpha: 0.1),
            iconColor: AppColors.catPrivate,
            title: "Sign Out",
            hasDivider: false,
            onTap: () => _showSignOutDialog(context),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildFooter(bool isDark) {
    return Column(
      children: [
        Text(
          "GDA Vault AI v1.0.0",
          style: AppTextStyles.dmSans.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: (isDark ? Colors.white : AppColors.navyDark).withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Galiyat Development Authority · Abbottabad",
          style: AppTextStyles.dmSans.copyWith(
            fontSize: 10,
            color: (isDark ? Colors.white : AppColors.navyDark).withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Sign Out?", style: AppTextStyles.playfairDisplay.copyWith(fontWeight: FontWeight.bold)),
          content: Text(
            "Are you sure you want to sign out from the GDA Vault AI system?",
            style: AppTextStyles.dmSans.copyWith(fontSize: 14),
          ),
          actions: [
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Sign Out", style: TextStyle(color: AppColors.catPrivate, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class _SettingsListItem extends StatelessWidget {
  const _SettingsListItem({
    required this.isDark,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
    this.hasDivider = true,
  });

  final bool isDark;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            border: hasDivider
                ? Border(
                    bottom: BorderSide(
                      color: AppColors.divider.withValues(alpha: isDark ? 0.05 : 0.1),
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.navyDark,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

