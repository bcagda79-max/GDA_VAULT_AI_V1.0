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
                color: AppColors.charcoal.withValues(alpha: 0.4),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            _buildBigButton(
              context: context,
              title: 'Categories',
              subtitle: 'Board, Trust, Town & more',
              badge: null,
              icon: Icons.folder_copy_rounded,
              isPrimary: true,
              isDark: isDark,
              onTap: () => context.push('/categories'),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 10),
            _buildBigButton(
              context: context,
              title: 'Add New File',
              subtitle: 'Scan or import a document',
              icon: Icons.add_circle_outline_rounded,
              isPrimary: false,
              isDark: isDark,
              onTap: () => context.go('/dashboard/add'),
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
            const SizedBox(height: 10),
            _buildBigButton(
              context: context,
              title: 'Offline Files',
              subtitle: 'Open cached documents without internet',
              icon: Icons.cloud_done_rounded,
              isPrimary: false,
              isDark: isDark,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDark, AppColors.navyLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
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
                    color: AppColors.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'GDA VAULT',
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _getGreeting(),
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Galiyat Development Authority',
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _getFormattedDate(),
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 80,
            height: 80,
            child: Image.asset(
              'assets/images/gda_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  'GDA',
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
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
    String? badge,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
    bool isDark = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppColors.navyDark, AppColors.navyLight],
                )
              : null,
          color: isPrimary
              ? null
              : (isDark
                    ? AppColors.darkCard
                    : AppColors.navyDark.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? AppColors.navyDark.withValues(alpha: 0.3)
                  : AppColors.gdaGreen.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.12)
                        : null,
                    gradient: isPrimary
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.gdaGreen, AppColors.navyLight],
                          ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: isPrimary ? 20 : 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isPrimary
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkText
                                  : AppColors.charcoal),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 10,
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.55)
                            : AppColors.charcoal.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.charcoal.withValues(alpha: 0.3),
                ),
              ],
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
                color: AppColors.charcoal.withValues(alpha: 0.4),
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
                color: AppColors.navyDark.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.navyDark.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'See All',
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 12,
                      color: AppColors.navyDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: AppColors.navyDark,
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
        height: 180,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.navyDark,
            strokeWidth: 2,
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
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navyDark.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.insert_drive_file_outlined,
                size: 32,
                color: AppColors.navyDark.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
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
                color: (isDark ? AppColors.darkText : AppColors.charcoal)
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _recentlyOpened.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
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
        width: 145,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.navyDark.withValues(alpha: 0.03),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 48,
                        color: categoryColor.withValues(alpha: 0.7),
                      ),
                    ),
                    Positioned(
                      right: -10,
                      top: 20,
                      bottom: 20,
                      child: Container(
                        width: 20,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkText : AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 10,
                        color:
                            (isDark ? AppColors.darkText : AppColors.charcoal)
                                .withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(document.uploadedAt),
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 10,
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            number,
            style:
                (isDark
                        ? AppTextStyles.statNumberDark
                        : AppTextStyles.statNumber)
                    .copyWith(fontSize: 20),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 9,
              color: (isDark ? AppColors.darkText : AppColors.charcoal)
                  .withValues(alpha: 0.45),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
