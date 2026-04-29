// lib/features/dashboard/tabs/settings_tab.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/providers/theme_provider.dart';

/// The settings tab, allowing user to configure the app.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(
      themeProvider.select((mode) => mode == ThemeMode.dark),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.all(
                AppSpacing.md,
              ).copyWith(top: AppSpacing.lg),
              child: Text(
                "Settings",
                style: AppTextStyles.headlineMedium.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.charcoal,
                ),
              ),
            ),
            _buildProfileCard(),
            const SizedBox(height: AppSpacing.md),
            _buildStorageCard(isDark),
            const SizedBox(height: AppSpacing.lg),
            _buildSettingsList(context, ref, isDark),
            const SizedBox(height: AppSpacing.xl),
            Text(
              "GDA Vault AI v1.0.0",
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: (isDark ? AppColors.darkText : AppColors.charcoal)
                    .withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "Galiyat Development Authority · Abbottabad",
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 9,
                color: (isDark ? AppColors.darkText : AppColors.charcoal)
                    .withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDark, Color(0xFF1A3A6B)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "OA",
                style: AppTextStyles.headlineMedium.copyWith(
                  fontSize: 20,
                  color: AppColors.navyDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Officer Ahmed",
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.white,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "Senior Archivist",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "Authority HQ · Abbottabad",
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Storage",
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark ? AppColors.darkText : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                "42.6 GB used of 100 GB",
                style: AppTextStyles.bodySmall.copyWith(
                  color: (isDark ? AppColors.darkText : AppColors.charcoal)
                      .withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              Text(
                "42%",
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: 0.426,
              backgroundColor: isDark ? AppColors.darkBg : AppColors.slate,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.brightness_6,
            iconBgColor: AppColors.gold.withValues(alpha: 0.1),
            iconColor: AppColors.gold,
            title: "Dark Mode",
            trailing: CupertinoSwitch(
              value: isDark,
              onChanged: (value) =>
                  ref.read(themeProvider.notifier).toggleTheme(),
              activeTrackColor: AppColors.gold,
            ),
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.folder_shared_rounded,
            iconBgColor: AppColors.catBoard.withValues(alpha: 0.1),
            iconColor: AppColors.catBoard,
            title: "Manage Categories",
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.sync,
            iconBgColor: AppColors.gdaGreen.withValues(alpha: 0.1),
            iconColor: AppColors.gdaGreen,
            title: "Sync & Backup",
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.language,
            iconBgColor: AppColors.catAdmin.withValues(alpha: 0.1),
            iconColor: AppColors.catAdmin,
            title: "Language",
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "English",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.info_outline,
            iconBgColor: isDark ? AppColors.darkSurface : AppColors.slate,
            iconColor: (isDark ? AppColors.darkText : AppColors.charcoal)
                .withValues(alpha: 0.6),
            title: "About GDA Vault AI",
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.logout,
            iconBgColor: AppColors.catPrivate.withValues(alpha: 0.1),
            iconColor: AppColors.catPrivate,
            title: "Sign Out",
            hasDivider: false,
            onTap: () => _showSignOutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Sign Out?"),
          content: const Text("Are you sure you want to sign out?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Sign Out"),
              onPressed: () {
                Navigator.of(context).pop();
                // Perform sign out logic
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
    final trailingWidget = trailing;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: hasDivider
                ? Border(
                    bottom: BorderSide(
                      color: AppColors.divider.withValues(alpha: isDark ? 0.1 : 0.5),
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.charcoal,
                  ),
                ),
              ),
              ?trailingWidget,
            ],
          ),
        ),
      ),
    );
  }
}
