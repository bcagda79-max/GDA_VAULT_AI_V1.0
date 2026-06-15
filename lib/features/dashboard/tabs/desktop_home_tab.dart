import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/models/document_model.dart';
import 'package:gda_vault_ai/providers/profile_provider.dart';
import 'package:gda_vault_ai/widgets/gda_stat_card.dart';
import 'package:gda_vault_ai/widgets/gda_quick_action_card.dart';
import 'package:gda_vault_ai/widgets/gda_doc_row.dart';
import 'package:gda_vault_ai/widgets/gda_status_chip.dart';
import 'package:intl/intl.dart';

class DesktopHomeTab extends ConsumerWidget {
  final Map<String, dynamic> stats;
  final List<DocumentModel> recentlyOpened;
  final bool statsLoading;
  final bool recentOpenedLoading;
  final String Function() getGreeting;
  final String Function() getFormattedDate;
  final String Function(dynamic) formatTotalDocs;
  final String Function(dynamic) formatTotalPages;
  final Future<void> Function() onRefresh;
  final bool isDark;

  const DesktopHomeTab({
    super.key,
    required this.stats,
    required this.recentlyOpened,
    required this.statsLoading,
    required this.recentOpenedLoading,
    required this.getGreeting,
    required this.getFormattedDate,
    required this.formatTotalDocs,
    required this.formatTotalPages,
    required this.onRefresh,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppTokens.lightBrandPrimary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: Column(
          children: [
            _buildWelcomeBanner(context).animate().fadeIn(duration: 400.ms).slideY(begin: -0.03, end: 0),
            const SizedBox(height: 24),
            _buildStatsRow().animate().fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildLeftPanel(context, ref)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: _buildRightPanel(context)
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideX(begin: 0.03, end: 0),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141414) : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark ? const Color(0xFF272727) : const Color(0xFFE4E7EC),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "All systems operational",
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF8A8A8A) : AppTokens.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "SECURE SESSION ACTIVE",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF22C55E),
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                getGreeting(),
                style: AppTextStyles.displayLg.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFEBEBEB) : Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Galiyat Development Authority — Document Intelligence Platform",
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF8A8A8A) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 13, color: Colors.white.withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                    Text(
                      getFormattedDate(),
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Opacity(
            opacity: 0.85,
            child: ClipOval(
              child: Image.asset(
                'assets/images/gda_logo.png',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(width: 72, height: 72),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    if (statsLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(color: AppTokens.lightBrandPrimary)),
      );
    }
    
    return Row(
      children: [
        Expanded(child: GdaStatCard(
          label: 'DOCS',
          value: formatTotalDocs(stats['total_documents']),
          icon: Icons.description_outlined,
        ).animate().fadeIn(delay: 0.ms).slideX(begin: 0.05, end: 0)),
        const SizedBox(width: 16),
        Expanded(child: GdaStatCard(
          label: 'PAGES',
          value: formatTotalPages(stats['total_pages']),
          icon: Icons.auto_stories_outlined,
        ).animate().fadeIn(delay: 50.ms).slideX(begin: 0.05, end: 0)),
        const SizedBox(width: 16),
        Expanded(child: GdaStatCard(
          label: 'CATEGORIES',
          value: '${stats['category_count'] ?? 0}',
          icon: Icons.folder_copy_outlined,
        ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.05, end: 0)),
        const SizedBox(width: 16),
        Expanded(child: GdaStatCard(
          label: 'STORAGE',
          value: (stats['total_size_gb'] as double? ?? 0.0).toStringAsFixed(2),
          icon: Icons.sd_storage_outlined,
        ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05, end: 0)),
      ],
    );
  }

  Widget _buildLeftPanel(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            "QUICK ACTIONS",
            style: AppTextStyles.labelSm.copyWith(
              color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: GdaQuickActionCard(
                title: 'Categories',
                subtitle: 'View folders & files',
                icon: Icons.folder_copy_outlined,
                onTap: () => context.push('/categories'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GdaQuickActionCard(
                title: 'Add New File',
                subtitle: 'Import or scan new',
                icon: Icons.document_scanner_outlined,
                onTap: () {
                  if (!ref.read(isAdminProvider)) {
                    context.go('/access-denied');
                    return;
                  }
                  context.go('/dashboard/add');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GdaQuickActionCard(
                title: 'Offline Vault',
                subtitle: 'Access without internet',
                icon: Icons.cloud_off_outlined,
                onTap: () => context.push('/dashboard/offline-documents'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRightPanel(BuildContext context) {
    final bgSurface = isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight = isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final textTertiary = isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final brandPrimary = isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;

    return Container(
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: borderLight),
        boxShadow: isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "RECENT ACTIVITY",
                  style: AppTextStyles.labelSm.copyWith(color: textTertiary),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.push('/dashboard/recent-documents'),
                    child: Text(
                      "VIEW ALL",
                      style: AppTextStyles.labelSm.copyWith(color: brandPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: borderLight),
          
          if (recentOpenedLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (recentlyOpened.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: textTertiary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recent documents',
                      style: AppTextStyles.bodyMd.copyWith(color: textTertiary),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentlyOpened.take(5).toList().asMap().entries.map(
                  (entry) => GdaDocRow(
                    filename: entry.value.fileName,
                    date: DateFormat.yMMMd().format(DateTime.parse(entry.value.uploadedAt.toIso8601String())),
                    showDivider: entry.key != 4, // Don't show divider on last item
                    onTap: () => context.push('/categories/view', extra: entry.value),
                  ),
                ),
        ],
      ),
    );
  }
}

