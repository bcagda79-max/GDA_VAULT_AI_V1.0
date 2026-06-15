// lib/features/dashboard/tabs/settings_tab.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gda_vault_ai/core/services/auth_service.dart';
import 'package:go_router/go_router.dart';

import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/features/ai_chat/providers/chat_provider.dart';
import 'package:gda_vault_ai/features/ai_chat/providers/chat_font_size_provider.dart';
import 'package:gda_vault_ai/features/ai_chat/models/chat_state.dart';
import 'package:gda_vault_ai/features/ai_chat/widgets/default_category_selector_sheet.dart';
import 'package:gda_vault_ai/providers/theme_provider.dart';
import 'package:gda_vault_ai/providers/profile_provider.dart';
import 'package:gda_vault_ai/features/dashboard/providers/dashboard_stats_provider.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider.select((mode) => mode == ThemeMode.dark));
    final bgPage = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgPage,
      body: Column(
        children: [
          Container(
            height: 56,
            width: double.infinity,
            color: const Color(0xFF1C2536),
            child: const Center(
              child: Text(
                "SETTINGS",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 860;
                
                final content = SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: isDesktop ? const EdgeInsets.all(24) : const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAccountSection(context, ref, isDark),
                      const SizedBox(height: 20),
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildStorageSection(context, ref, isDark)),
                          ],
                        )
                      else
                        _buildStorageSection(context, ref, isDark),
                      const SizedBox(height: 20),
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildAppearanceSection(context, ref, isDark)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildAppPreferencesSection(context, ref, isDark)),
                          ],
                        )
                      else ...[
                        _buildAppearanceSection(context, ref, isDark),
                        const SizedBox(height: 20),
                        _buildAppPreferencesSection(context, ref, isDark),
                      ],
                      const SizedBox(height: 20),
                      _buildSupportSection(context, ref, isDark),
                      const SizedBox(height: 20),
                      _buildDangerZoneSection(context, ref, isDark),
                      const SizedBox(height: 20),
                      _buildAuthSection(context, isDark),
                      const SizedBox(height: 32),
                      _buildFooter(isDark),
                    ],
                  ),
                );

                if (isDesktop) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: content,
                    ),
                  );
                }
                return content;
              },
            ),
          ),
        ],
      ).animate().fadeIn(duration: 280.ms),
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref, bool isDark) {
    final bgSurface = isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF);
    final borderLight = isDark ? const Color(0xFF272727) : const Color(0xFFE4E7EC);
    final textPrimary = isDark ? const Color(0xFFEBEBEB) : const Color(0xFF101828);
    final textSecondary = isDark ? const Color(0xFF8A8A8A) : const Color(0xFF475467);
    final textTertiary = isDark ? const Color(0xFF555555) : const Color(0xFF98A2B3);
    final brandPrimary = isDark ? const Color(0xFFEBEBEB) : const Color(0xFF141414);
    final bgPage = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);

    final isAdmin = ref.watch(isAdminProvider);
    final profileAsync = ref.watch(profileProvider);
    final email = profileAsync.value?['email'] ?? "";
    
    String displayName = "User";
    if (profileAsync.value != null && profileAsync.value!['display_name'] != null) {
      displayName = profileAsync.value!['display_name'];
    }
    
    String initials = "U";
    if (displayName.isNotEmpty) {
      final parts = displayName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = parts[0][0].toUpperCase();
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight, width: 0.5),
        boxShadow: isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowSm,
      ),
      child: InkWell(
        onTap: () {}, // Account navigation if exists
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: brandPrimary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: brandPrimary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF141414) : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isAdmin ? brandPrimary.withValues(alpha: 0.1) : bgPage,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isAdmin ? brandPrimary.withValues(alpha: 0.2) : borderLight,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      isAdmin ? "Administrator" : "Standard User",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isAdmin ? brandPrimary : textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSection(BuildContext context, WidgetRef ref, bool isDark) {
    final bgSurface = isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF);
    final borderLight = isDark ? const Color(0xFF272727) : const Color(0xFFE4E7EC);
    final textPrimary = isDark ? const Color(0xFFEBEBEB) : const Color(0xFF101828);
    final textSecondary = isDark ? const Color(0xFF8A8A8A) : const Color(0xFF475467);
    final textTertiary = isDark ? const Color(0xFF555555) : const Color(0xFF98A2B3);
    final brandPrimary = isDark ? const Color(0xFFEBEBEB) : const Color(0xFF141414);
    final brandSurface = isDark ? const Color(0xFF1A2744) : const Color(0xFFEBF2FF);
    final statusError = isDark ? const Color(0xFFF97066) : const Color(0xFFF04438);

    final statsAsync = ref.watch(dashboardStatsProvider);
    final double usedGB = (statsAsync.value?['total_size_gb'] as num?)?.toDouble() ?? 0.0;
    const double totalGB = 100.0;
    final double freeGB = (totalGB - usedGB).clamp(0.0, totalGB);
    final double usedFraction = (usedGB / totalGB).clamp(0.0, 1.0);
    final String usedPercent = (usedFraction * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel("STORAGE"),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderLight, width: 0.5),
            boxShadow: isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: brandSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderLight, width: 0.5),
                        ),
                        child: Icon(Icons.cloud_outlined, size: 17, color: brandPrimary),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "GDA Cloud Storage",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            "Supabase Storage",
                            style: TextStyle(
                              fontSize: 11,
                              color: textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderLight, width: 0.5),
                    ),
                    child: Text(
                      "$usedPercent%",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${usedGB.toStringAsFixed(1)} GB",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        "used of ${totalGB.toInt()} GB",
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${freeGB.toStringAsFixed(1)} GB",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        "available",
                        style: TextStyle(
                          fontSize: 10,
                          color: textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(builder: (context, constraints) {
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: usedFraction),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF272727) : const Color(0xFFE4E7EC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: value > 0.8
                                ? statusError
                                : value > 0.5
                                    ? const Color(0xFFF59E0B)
                                    : brandPrimary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 6),
              Text(
                "Storage resets monthly · Abbottabad, KP",
                style: TextStyle(
                  fontSize: 10,
                  color: textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context, WidgetRef ref, bool isDark) {
    final bgSurface = isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF);
    final borderLight = isDark ? const Color(0xFF272727) : const Color(0xFFE4E7EC);
    final textSecondary = isDark ? const Color(0xFF8A8A8A) : const Color(0xFF475467);
    final textTertiary = isDark ? const Color(0xFF555555) : const Color(0xFF98A2B3);
    final dividerColor = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0);
    
    final fontSize = ref.watch(chatFontSizeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel("APPEARANCE"),
        Container(
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderLight, width: 0.5),
            boxShadow: isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowSm,
          ),
          child: Column(
            children: [
              _SettingsRow(
                isDark: isDark,
                icon: Icons.dark_mode_outlined,
                label: "Dark Mode",
                trailing: Switch(
                  value: isDark,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF2563EB),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: isDark ? const Color(0xFF333333) : const Color(0xFFD1D5DB),
                  onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(),
                ),
              ),
              Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: dividerColor),
              _SettingsRow(
                isDark: isDark,
                icon: Icons.text_fields_outlined,
                label: "Chat Font Size",
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${fontSize.toStringAsFixed(1)} px",
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: textTertiary),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => ChatFontSizeDialog(
                      initialSize: fontSize,
                      isDark: isDark,
                      onSave: (size) => ref.read(chatFontSizeProvider.notifier).setChatFontSize(size),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppPreferencesSection(BuildContext context, WidgetRef ref, bool isDark) {
    final bgSurface = isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF);
    final borderLight = isDark ? const Color(0xFF272727) : const Color(0xFFE4E7EC);
    final textSecondary = isDark ? const Color(0xFF8A8A8A) : const Color(0xFF475467);
    final textTertiary = isDark ? const Color(0xFF555555) : const Color(0xFF98A2B3);
    final dividerColor = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0);
    
    final chatState = ref.watch(chatProvider);
    final defaultCategoryNames = chatState.categories
        .where((cat) => cat.parentId == null && chatState.defaultCategoryIds.contains(cat.id))
        .map((cat) => cat.name)
        .toList();
    
    final categoryName = defaultCategoryNames.isEmpty ? "Configure" : defaultCategoryNames.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel("APP PREFERENCES"),
        Container(
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderLight, width: 0.5),
            boxShadow: isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowSm,
          ),
          child: Column(
            children: [
              _SettingsRow(
                isDark: isDark,
                icon: Icons.category_outlined,
                label: "Default Chat Categories",
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        categoryName,
                        style: TextStyle(fontSize: 13, color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: textTertiary),
                  ],
                ),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => DraggableScrollableSheet(
                      initialChildSize: 0.75,
                      minChildSize: 0.5,
                      maxChildSize: 0.9,
                      expand: false,
                      builder: (_, scrollController) => const DefaultCategorySelectorSheet(),
                    ),
                  );
                },
              ),
              Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: dividerColor),
              _SettingsRow(
                isDark: isDark,
                icon: Icons.language_outlined,
                label: "Language",
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "English",
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: textTertiary),
                  ],
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context, WidgetRef ref, bool isDark) {
    final bgSurface = isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF);
    final borderLight = isDark ? const Color(0xFF272727) : const Color(0xFFE4E7EC);
    final textTertiary = isDark ? const Color(0xFF555555) : const Color(0xFF98A2B3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel("SUPPORT"),
        Container(
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderLight, width: 0.5),
            boxShadow: isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowSm,
          ),
          child: _SettingsRow(
            isDark: isDark,
            icon: Icons.help_outline,
            label: "Help & Documentation",
            trailing: Icon(Icons.chevron_right, size: 16, color: textTertiary),
            onTap: () => _showAboutDialog(context, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZoneSection(BuildContext context, WidgetRef ref, bool isDark) {
    final bgSurface = isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF);
    final statusError = isDark ? const Color(0xFFF97066) : const Color(0xFFF04438);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel("DANGER ZONE"),
        Container(
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2), width: 1.0),
            boxShadow: isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowSm,
          ),
          child: _SettingsRow(
            isDark: isDark,
            icon: Icons.delete_outline,
            iconColor: statusError,
            iconBg: isDark ? const Color(0xFF2D1010) : const Color(0xFFFEE4E2),
            label: "Delete All Chats",
            labelColor: statusError,
            trailing: Icon(Icons.chevron_right, size: 16, color: statusError),
            onTap: () => _showDeleteAllChatsDialog(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthSection(BuildContext context, bool isDark) {
    final bgSurface = isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF);
    final borderLight = isDark ? const Color(0xFF272727) : const Color(0xFFE4E7EC);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel("ACCOUNT"),
        Container(
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderLight, width: 0.5),
            boxShadow: isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowSm,
          ),
          child: _SettingsRow(
            isDark: isDark,
            icon: Icons.logout,
            iconColor: isDark ? const Color(0xFFEBEBEB) : const Color(0xFF101828),
            label: "Logout",
            trailing: const Icon(Icons.chevron_right, size: 16),
            onTap: () async {
              await AuthService.instance.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    final textSecondary = isDark ? const Color(0xFF8A8A8A) : const Color(0xFF475467);
    final textTertiary = isDark ? const Color(0xFF555555) : const Color(0xFF98A2B3);

    return Column(
      children: [
        Opacity(
          opacity: 0.6,
          child: ClipOval(
            child: Image.asset('assets/images/gda_logo.png', width: 28, height: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "GDA Vault AI",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Galiyat Development Authority · Abbottabad, KP",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Version 1.0.0",
          style: TextStyle(
            fontSize: 10,
            color: textTertiary,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showAboutDialog(BuildContext context, bool isDark) {
    final brandPrimary = isDark ? const Color(0xFFEBEBEB) : const Color(0xFF141414);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTokens.darkBgSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: brandPrimary.withValues(alpha: 0.3)),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/gda_logo.png', width: 80, height: 80),
              const SizedBox(height: 20),
              Text(
                "GDA Vault AI",
                style: AppTextStyles.headingMd.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : brandPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "GDA Vault AI is an intelligent, secure document management system designed exclusively for the Galiyat Development Authority. It provides seamless categorization, local caching, and AI-powered insights for instant access to critical departmental archives.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 13,
                  height: 1.5,
                  color: (isDark ? Colors.white : AppTokens.lightTextPrimary).withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    "Close",
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAllChatsDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusError = isDark ? const Color(0xFFF97066) : const Color(0xFFF04438);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(dialogContext).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Delete all chats?",
            style: AppTextStyles.headingMd.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "This will permanently remove every locally saved chat session and message from this device.",
            style: AppTextStyles.bodyMd.copyWith(fontSize: 14),
          ),
          actions: [
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text(
                "Delete All",
                style: TextStyle(
                  color: statusError,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref.read(chatProvider.notifier).deleteAllChats();
              },
            ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary = isDark ? const Color(0xFF555555) : const Color(0xFF98A2B3);

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBg;
  final String label;
  final Color? labelColor;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.isDark,
    required this.icon,
    this.iconColor,
    this.iconBg,
    required this.label,
    this.labelColor,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? const Color(0xFFEBEBEB) : const Color(0xFF101828);
    final defaultIconBg = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF9FAFB);
    final defaultIconBorder = isDark ? const Color(0xFF272727) : const Color(0xFFE4E7EC);
    final defaultIconColor = isDark ? const Color(0xFF8A8A8A) : const Color(0xFF667085);
    final rippleColor = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        splashColor: rippleColor,
        highlightColor: rippleColor,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg ?? defaultIconBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: defaultIconBorder, width: 0.5),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 16,
                    color: iconColor ?? defaultIconColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: labelColor ?? textPrimary,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class ChatFontSizeDialog extends StatefulWidget {
  final double initialSize;
  final bool isDark;
  final Future<void> Function(double size) onSave;

  const ChatFontSizeDialog({
    super.key,
    required this.initialSize,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<ChatFontSizeDialog> createState() => _ChatFontSizeDialogState();
}

class _ChatFontSizeDialogState extends State<ChatFontSizeDialog> {
  late double _tempSize;

  @override
  void initState() {
    super.initState();
    _tempSize = widget.initialSize.clamp(12.0, 25.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final brandPrimary = isDark ? const Color(0xFFEBEBEB) : const Color(0xFF141414);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: isDark ? AppTokens.darkBgSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: brandPrimary.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: brandPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: brandPrimary.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(
                Icons.text_fields_rounded,
                color: brandPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Chat Font Size',
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMd.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : brandPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adjust how AI responses and your chat messages look.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 12,
                height: 1.4,
                color: isDark
                    ? Colors.white70
                    : AppTokens.lightTextPrimary.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppTokens.darkBgPage : AppTokens.lightBgPage,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppTokens.lightBorderLight,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Sample AI chat text preview',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: _tempSize,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppTokens.lightTextPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '12 px',
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white54
                              : AppTokens.lightTextPrimary.withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        '${_tempSize.toStringAsFixed(1)} px',
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: brandPrimary,
                        ),
                      ),
                      Text(
                        '25 px',
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white54
                              : AppTokens.lightTextPrimary.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: brandPrimary,
                      inactiveTrackColor: brandPrimary.withValues(
                        alpha: 0.15,
                      ),
                      thumbColor: brandPrimary,
                      overlayColor: brandPrimary.withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _tempSize,
                      min: 12,
                      max: 25,
                      divisions: 26,
                      onChanged: (value) {
                        setState(() => _tempSize = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : AppTokens.lightTextPrimary,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppTokens.lightBorderMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(_tempSize);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Save',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
