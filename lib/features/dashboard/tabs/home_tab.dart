import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/services/pdf_viewer_service.dart';
import 'package:gda_vault_ai/core/services/supabase_service.dart';
import 'package:gda_vault_ai/core/utils/responsive_helper.dart';
import 'package:gda_vault_ai/models/document_model.dart';
import 'package:gda_vault_ai/features/dashboard/tabs/desktop_home_tab.dart';
import 'package:gda_vault_ai/providers/profile_provider.dart';

import 'package:gda_vault_ai/widgets/gda_stat_card.dart';
import 'package:gda_vault_ai/widgets/gda_quick_action_card.dart';
import 'package:gda_vault_ai/widgets/gda_doc_row.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  Map<String, dynamic> _stats = {
    'total_documents': 0,
    'total_pages': 0,
    'total_size_gb': 0.0,
    'category_count': 5,
  };
  List<DocumentModel> _recentlyOpened = [];
  bool _statsLoading = true;
  bool _recentOpenedLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadRecentlyOpened();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getFormattedDate() {
    return DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
  }

  Future<void> _loadStats() async {
    try {
      final stats = await SupabaseService.instance.getDashboardStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _statsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statsLoading = false);
      debugPrint('Dashboard stats error: $e');
    }
  }

  Future<void> _loadRecentlyOpened() async {
    try {
      final docs = await PdfViewerService.instance.getRecentlyOpenedDocuments();
      if (!mounted) return;
      setState(() {
        _recentlyOpened = docs;
        _recentOpenedLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _recentOpenedLoading = false);
      debugPrint('Recent opened docs error: $e');
    }
  }

  String _formatTotalPages(dynamic totalPages) {
    final pages = (totalPages is num)
        ? totalPages.toInt()
        : int.tryParse('$totalPages') ?? 0;
    if (pages > 1000) {
      return '${(pages / 1000).toStringAsFixed(1)}k';
    }
    return pages.toString();
  }

  String _formatTotalDocs(dynamic totalDocs) {
    final docs = (totalDocs is num)
        ? totalDocs.toInt()
        : int.tryParse('$totalDocs') ?? 0;
    return docs.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLargeScreen = ResponsiveHelper.isDesktop(context);

    if (isLargeScreen) {
      return DesktopHomeTab(
        stats: _stats,
        recentlyOpened: _recentlyOpened,
        statsLoading: _statsLoading,
        recentOpenedLoading: _recentOpenedLoading,
        getGreeting: _getGreeting,
        getFormattedDate: _getFormattedDate,
        formatTotalDocs: _formatTotalDocs,
        formatTotalPages: _formatTotalPages,
        onRefresh: () async {
          await Future.wait([_loadStats(), _loadRecentlyOpened()]);
        },
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      color: AppTokens.lightBrandPrimary,
      onRefresh: () async {
        await Future.wait([_loadStats(), _loadRecentlyOpened()]);
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 100, // scrolling above bottom nav
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            _buildWelcomeBanner()
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.04, end: 0),
            
            const SizedBox(height: 20),
            
            // Stats Row (3 items)
            _buildStatsRow()
                .animate()
                .fadeIn(delay: 150.ms, duration: 400.ms)
                .slideY(begin: 0.04, end: 0),
            
            const SizedBox(height: 24),
            
            // Browse section
            Text(
              'BROWSE',
              style: AppTextStyles.labelSm.copyWith(
                color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
              ),
            ),
            const SizedBox(height: 12),
            GdaQuickActionCard(
              title: 'Categories',
              subtitle: 'View folders & files',
              icon: Icons.folder_copy_outlined,
              onTap: () => context.push('/categories'),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 12),
            GdaQuickActionCard(
              title: 'Add New File',
              subtitle: 'Import or scan new',
              icon: Icons.document_scanner_outlined,
              onTap: () {
                context.go('/dashboard/add');
              },
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
            const SizedBox(height: 12),
            GdaQuickActionCard(
              title: 'Offline Vault',
              subtitle: 'Access without internet',
              icon: Icons.cloud_off_outlined,
              onTap: () => context.push('/dashboard/offline-documents'),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            
            const SizedBox(height: 32),
            
            // Recent Scanned list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT SCANNED',
                  style: AppTextStyles.labelSm.copyWith(
                    color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/dashboard/recent-documents'),
                  child: Text(
                    "VIEW ALL",
                    style: AppTextStyles.labelSm.copyWith(
                      color: isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
            const SizedBox(height: 12),
            _buildRecentDocsBody().animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTokens.darkBgSidebar : AppTokens.lightBgSidebar;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTokens.lightStatusSuccess,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "Secure Session Active",
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTokens.lightStatusSuccess,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getGreeting(),
            style: AppTextStyles.displaySm.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Galiyat Development Authority",
            style: AppTextStyles.bodySm.copyWith(
              color: AppTokens.lightTextSidebar,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalDocs = _statsLoading ? '...' : _formatTotalDocs(_stats['total_documents']);
    final totalPages = _statsLoading ? '...' : _formatTotalPages(_stats['total_pages']);
    const totalCategories = '5';

    return Row(
      children: [
        Expanded(
          child: GdaStatCard(
            label: 'DOCS',
            value: totalDocs,
            icon: Icons.description_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GdaStatCard(
            label: 'PAGES',
            value: totalPages,
            icon: Icons.auto_stories_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GdaStatCard(
            label: 'CATEGORIES',
            value: totalCategories,
            icon: Icons.folder_copy_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDocsBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSurface = isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight = isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final textTertiary = isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;

    if (_recentOpenedLoading) {
      return SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: AppTokens.lightBrandPrimary),
        ),
      );
    }

    if (_recentlyOpened.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: bgSurface,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border: Border.all(color: borderLight),
          boxShadow: isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowXs,
        ),
        child: Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 32,
              color: textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No recent documents',
              style: AppTextStyles.bodyMd.copyWith(color: textTertiary),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: borderLight),
        boxShadow: isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowXs,
      ),
      child: Column(
        children: _recentlyOpened
            .take(4).toList().asMap().entries
            .map(
              (entry) => GdaDocRow(
                filename: entry.value.fileName,
                date: DateFormat.yMMMd().format(DateTime.parse(entry.value.uploadedAt.toIso8601String())),
                showDivider: entry.key != 3, // Assuming max 4
                onTap: () => context.push('/categories/view', extra: entry.value),
              ),
            )
            .toList(),
      ),
    );
  }
}

