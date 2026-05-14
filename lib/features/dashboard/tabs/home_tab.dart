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

/// The home tab of the dashboard, showing a summary and quick actions.
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
      color: AppColors.gold,
      onRefresh: () async {
        await Future.wait([_loadStats(), _loadRecentlyOpened()]);
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 100,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isLargeScreen ? 1180 : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingCard(isDark)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.04, end: 0),
                const SizedBox(height: 16),
                _buildStatsRow(isDark, isLargeScreen)
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.04, end: 0),
                const SizedBox(height: 20),
                Text(
                  'BROWSE',
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: (isDark ? AppColors.darkText : AppColors.charcoal)
                        .withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                _buildBigButton(
                  context: context,
                  title: 'Categories',
                  subtitle: 'Board, Trust, Town & more',
                  icon: Icons.folder_copy_rounded,
                  bgColors: isDark
                      ? [AppColors.secondaryBlueDark, AppColors.darkCard]
                      : [AppColors.primaryBlue, const Color(0xFF3B82F6)],
                  onTap: () => context.push('/categories'),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 10),
                _buildBigButton(
                  context: context,
                  title: 'Add New File',
                  subtitle: 'Scan or import a document',
                  icon: Icons.add_circle_outline_rounded,
                  bgColors: [AppColors.primaryBlue, const Color(0xFF2563EB)],
                  onTap: () => context.go('/dashboard/add'),
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                const SizedBox(height: 10),
                _buildBigButton(
                  context: context,
                  title: 'Offline Files',
                  subtitle: 'Open cached documents without internet',
                  icon: Icons.cloud_done_rounded,
                  bgColors: isDark
                      ? [AppColors.secondaryBlueDark, const Color(0xFF111827)]
                      : [AppColors.secondarySlate, const Color(0xFF1F2937)],
                  onTap: () => context.push('/dashboard/offline-documents'),
                ).animate().fadeIn(delay: 275.ms, duration: 400.ms),
                const SizedBox(height: 24),
                _buildRecentDocsHeader(
                  isDark,
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                const SizedBox(height: 12),
                _buildRecentDocsBody(
                  context,
                  isDark,
                ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard(bool isDark) {
    final isLargeScreen = ResponsiveHelper.isDesktop(context);
    // Responsive padding and sizing
    final cardPadding = isLargeScreen ? 32.0 : 24.0;
    final logoSize = isLargeScreen ? 130.0 : 110.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkCard, AppColors.darkBg]
              : [AppColors.primaryBlue, AppColors.secondaryBlueDark],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isLargeScreen)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppColors.goldDark
                                      : AppColors.goldLightBrand)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                (isDark
                                        ? AppColors.goldDark
                                        : AppColors.goldLightBrand)
                                    .withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'SECURE VAULT',
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? AppColors.goldDark
                                : AppColors.goldLightBrand,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _getGreeting(),
                        style: AppTextStyles.playfairDisplay.copyWith(
                          fontSize: isLargeScreen ? 32 : 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Galiyat Development Authority',
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: isDark
                                  ? AppColors.goldDark
                                  : AppColors.goldLightBrand,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Text(
                                _getFormattedDate().toUpperCase(),
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppColors.goldDark
                                      : AppColors.goldLightBrand)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                (isDark
                                        ? AppColors.goldDark
                                        : AppColors.goldLightBrand)
                                    .withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'SECURE VAULT',
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? AppColors.goldDark
                                : AppColors.goldLightBrand,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _getGreeting(),
                        style: AppTextStyles.playfairDisplay.copyWith(
                          fontSize: isLargeScreen ? 32 : 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Galiyat Development Authority',
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: isDark
                                  ? AppColors.goldDark
                                  : AppColors.goldLightBrand,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Text(
                                _getFormattedDate().toUpperCase(),
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (isLargeScreen)
                SizedBox(
                  width: logoSize + 28,
                  height: logoSize,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: Image.asset(
                        'assets/images/gda_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // MOBILE LOGO: Positioned at the extreme right to satisfy "fully right side"
          if (!isLargeScreen)
            Positioned(
              right: -12, // Slight offset for a premium overlapping/edge-aligned look
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: 0.8,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: logoSize * 0.9,
                      maxHeight: logoSize * 0.9,
                    ),
                    child: Image.asset(
                      'assets/images/gda_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentDocsHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'RECENT DOCUMENTS',
          style: AppTextStyles.dmSans.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: (isDark ? AppColors.darkText : AppColors.charcoal)
                .withValues(alpha: 0.6),
            letterSpacing: 1.2,
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          child: Row(
            children: [
              Text(
                'See All',
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 12,
                  color: isDark ? AppColors.gold : AppColors.navyDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: isDark ? AppColors.gold : AppColors.navyDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isDark, bool isLargeScreen) {
    final totalDocs = _statsLoading
        ? '...'
        : _formatTotalDocs(_stats['total_documents']);
    final totalPages = _statsLoading
        ? '...'
        : _formatTotalPages(_stats['total_pages']);
    const totalCategories = '5';
    final gap = isLargeScreen ? 20.0 : 10.0;
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            number: totalDocs,
            label: 'Documents',
            icon: Icons.folder_copy_rounded,
            iconColor: AppColors.catBoard,
            isDark: isDark,
            isLargeScreen: isLargeScreen,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _StatBox(
            number: totalPages,
            label: 'Pages',
            icon: Icons.description_rounded,
            iconColor: AppColors.gdaGreen,
            isDark: isDark,
            isLargeScreen: isLargeScreen,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _StatBox(
            number: totalCategories,
            label: 'Categories',
            icon: Icons.category_rounded,
            iconColor: AppColors.gold,
            isDark: isDark,
            isLargeScreen: isLargeScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildBigButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required List<Color> bgColors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 68,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: bgColors,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: bgColors.first.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(icon, size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDocsBody(BuildContext context, bool isDark) {
    if (_recentOpenedLoading) {
      return SizedBox(
        height: 190,
        child: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppColors.gold : AppColors.navyDark,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_recentlyOpened.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : AppColors.navyDark.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isDark
                ? AppColors.divider
                : AppColors.navyDark.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.navyDark.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.divider
                      : AppColors.navyDark.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(
                Icons.insert_drive_file_outlined,
                size: 32,
                color: isDark
                    ? AppColors.darkText.withValues(alpha: 0.3)
                    : AppColors.navyDark.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Recent Documents',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Open a document to see it here',
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: (isDark ? AppColors.darkText : AppColors.charcoal)
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _recentlyOpened.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final doc = _recentlyOpened[index];
          return _RecentDocumentCard(
            document: doc,
            isDark: isDark,
            onTap: () {
              context.push(
                '/categories/sub/${doc.categoryId}/years/pdf',
                extra: {
                  'document': doc,
                  'categoryColor': doc.categoryColor ?? AppColors.navyDark,
                  'categoryName': doc.categoryName ?? 'Recent Documents',
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _RecentDocumentCard extends StatelessWidget {
  final DocumentModel document;
  final bool isDark;
  final VoidCallback onTap;

  const _RecentDocumentCard({
    required this.document,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = document.categoryColor ?? AppColors.navyDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : AppColors.navyDark.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isDark
                ? AppColors.divider
                : AppColors.navyDark.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? categoryColor.withValues(alpha: 0.1)
                      : categoryColor.withValues(alpha: 0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppColors.divider
                          : AppColors.navyDark.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: categoryColor.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 28,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -15,
                      top: 10,
                      bottom: 10,
                      child: Container(
                        width: 30,
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_rounded,
                            size: 11,
                            color:
                                (isDark
                                        ? AppColors.darkText
                                        : AppColors.charcoal)
                                    .withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${document.pageCount ?? 0} pgs',
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color:
                                  (isDark
                                          ? AppColors.darkText
                                          : AppColors.charcoal)
                                      .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color:
                                (isDark
                                        ? AppColors.darkText
                                        : AppColors.charcoal)
                                    .withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              DateFormat(
                                'dd MMM, hh:mm a',
                              ).format(document.uploadedAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w500,
                                color:
                                    (isDark
                                            ? AppColors.darkText
                                            : AppColors.charcoal)
                                        .withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final bool isLargeScreen;

  const _StatBox({
    required this.number,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    this.isLargeScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final paddingV = isLargeScreen ? 28.0 : 18.0;
    final iconSize = isLargeScreen ? 44.0 : 36.0;
    final numberFont = isLargeScreen ? 28.0 : 22.0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: paddingV, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.divider
              : AppColors.navyDark.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: isDark
                  ? iconColor.withValues(alpha: 0.15)
                  : iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: isDark ? 0.3 : 0.1),
                width: 0.5,
              ),
            ),
            child: Icon(icon, size: iconSize * 0.4, color: iconColor),
          ),
          SizedBox(height: isLargeScreen ? 14 : 12),
          Text(
            number,
            style:
                (isDark
                        ? AppTextStyles.statNumberDark
                        : AppTextStyles.statNumber)
                    .copyWith(
                      fontSize: numberFont,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: isLargeScreen ? 12 : 10,
              color: (isDark ? AppColors.darkText : AppColors.charcoal)
                  .withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
