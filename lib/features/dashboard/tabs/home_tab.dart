import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/services/pdf_viewer_service.dart';
import 'package:gda_vault_ai/core/services/supabase_service.dart';
import 'package:gda_vault_ai/models/document_model.dart';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingCard(
              isDark,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.04, end: 0),
            const SizedBox(height: 16),
            _buildStatsRow(isDark)
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
              bgColors: [AppColors.navyDark, AppColors.navyLight],
              onTap: () => context.push('/categories'),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 10),
            _buildBigButton(
              context: context,
              title: 'Add New File',
              subtitle: 'Scan or import a document',
              icon: Icons.add_circle_outline_rounded,
              bgColors: [AppColors.gdaGreen, AppColors.gdaGreenMid],
              onTap: () => context.go('/dashboard/add'),
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
            const SizedBox(height: 10),
            _buildBigButton(
              context: context,
              title: 'Offline Files',
              subtitle: 'Open cached documents without internet',
              icon: Icons.cloud_done_rounded,
              bgColors: [AppColors.catAdmin, const Color(0xFF6A2699)],
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
    );
  }

  Widget _buildGreetingCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF161E35), const Color(0xFF0A0F1E)]
              : [AppColors.navyDark, AppColors.navyMid],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative circle
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'SECURE VAULT',
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _getGreeting(),
                      style: AppTextStyles.playfairDisplay.copyWith(
                        fontSize: 26,
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
                        color: Colors.white.withValues(alpha: 0.5),
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
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getFormattedDate().toUpperCase(),
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/images/gda_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final totalDocs = _statsLoading
        ? '...'
        : _formatTotalDocs(_stats['total_documents']);
    final totalPages = _statsLoading
        ? '...'
        : _formatTotalPages(_stats['total_pages']);
    const totalCategories = '5';

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            number: totalDocs,
            label: 'Documents',
            icon: Icons.folder_copy_rounded,
            iconColor: AppColors.catBoard,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            number: totalPages,
            label: 'Pages',
            icon: Icons.description_rounded,
            iconColor: AppColors.gdaGreen,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            number: totalCategories,
            label: 'Categories',
            icon: Icons.category_rounded,
            iconColor: AppColors.gold,
            isDark: isDark,
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
            Row(
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

  Widget _buildRecentDocsHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECENT DOCUMENTS',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: (isDark ? AppColors.darkText : AppColors.charcoal)
                    .withValues(alpha: 0.5),
                letterSpacing: 1.2,
              ),
            ),
            Text(
              _recentOpenedLoading
                  ? 'Loading recent documents...'
                  : 'Recently opened documents',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 12,
                color: isDark ? AppColors.darkText : AppColors.charcoal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (!_recentOpenedLoading && _recentlyOpened.isNotEmpty)
          GestureDetector(
            onTap: () => context.push('/dashboard/recent-documents'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.gold.withValues(alpha: 0.1)
                    : AppColors.navyDark.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppColors.gold.withValues(alpha: 0.3)
                      : AppColors.navyDark.withValues(alpha: 0.12),
                ),
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
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: isDark ? AppColors.gold : AppColors.navyDark,
                  ),
                ],
              ),
            ),
          ),
      ],
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
                  Row(
                    children: [
                      Icon(
                        Icons.description_rounded,
                        size: 11,
                        color:
                            (isDark ? AppColors.darkText : AppColors.charcoal)
                                .withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${document.pageCount ?? 0} pgs',
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color:
                              (isDark ? AppColors.darkText : AppColors.charcoal)
                                  .withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d').format(document.uploadedAt),
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color:
                              (isDark ? AppColors.darkText : AppColors.charcoal)
                                  .withValues(alpha: 0.4),
                        ),
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

  const _StatBox({
    required this.number,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
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
            width: 36,
            height: 36,
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
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            number,
            style:
                (isDark
                        ? AppTextStyles.statNumberDark
                        : AppTextStyles.statNumber)
                    .copyWith(fontSize: 22, height: 1.0, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 10,
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
