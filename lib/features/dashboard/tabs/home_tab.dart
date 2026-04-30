// lib/features/dashboard/tabs/home_tab.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/features/add_document/providers/recent_scans_provider.dart';
import 'package:gda_vault_ai/models/document_model.dart';

/// The home tab of the dashboard, showing a summary and quick actions.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getFormattedDate() {
    return DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recentAsync = ref.watch(recentScansProvider);
    final recentFiles = recentAsync.when(
      data: (files) => files,
      loading: () => <File>[],
      error: (err, stack) => <File>[],
    );

    return SingleChildScrollView(
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
          _buildGreetingCard(isDark)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.04, end: 0),
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
            badge: '5',
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
          const SizedBox(height: 24),

          // ─── Recent Scans Section ──────────────────────────────────
          _buildRecentScansHeader(context, isDark, recentFiles.length)
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 12),
          _buildRecentScansBody(context, isDark, recentFiles, recentAsync)
              .animate()
              .fadeIn(delay: 350.ms, duration: 400.ms),
        ],
      ),
    );
  }

  // ── Greeting Card ─────────────────────────────────────────────────────────
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
                const SizedBox(height: 10),
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
              errorBuilder: (_, __, ___) => Center(
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

  // ── Stats Row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            number: '1,284',
            label: 'Documents',
            icon: Icons.folder_copy_rounded,
            iconColor: AppColors.catBoard,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            number: '70.2k',
            label: 'Pages',
            icon: Icons.description_rounded,
            iconColor: AppColors.gdaGreen,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            number: '5',
            label: 'Categories',
            icon: Icons.category_rounded,
            iconColor: AppColors.gold,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ── Big Action Button ─────────────────────────────────────────────────────
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
              : (isDark ? AppColors.darkCard : AppColors.navyDark.withValues(alpha: 0.05)),
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

  // ── Recent Scans Header ───────────────────────────────────────────────────
  Widget _buildRecentScansHeader(
    BuildContext context,
    bool isDark,
    int count,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECENT SCANS',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal.withValues(alpha: 0.4),
                letterSpacing: 1.2,
              ),
            ),
            Text(
              '$count file${count == 1 ? '' : 's'} scanned locally',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 12,
                color: isDark ? AppColors.darkText : AppColors.charcoal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (count > 0)
          GestureDetector(
            onTap: () => context.push('/recent-scans'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),
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

  // ── Recent Scans Body ─────────────────────────────────────────────────────
  Widget _buildRecentScansBody(
    BuildContext context,
    bool isDark,
    List<File> files,
    AsyncValue<List<File>> async,
  ) {
    if (async is AsyncLoading) {
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

    if (files.isEmpty) {
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
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
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
              'No Recent Files',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your recently scanned PDFs will appear here',
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
        itemCount: files.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final file = files[index];
          final fileName = file.path.split(Platform.pathSeparator).last;
          
          return Container(
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
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PDF Preview / Icon Area
                Expanded(child: Container(
                    width: double.infinity,
                    color: AppColors.navyDark.withValues(alpha: 0.03),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 48,
                            color: AppColors.catPrivate.withValues(alpha: 0.7),
                          ),
                        ),
                        // Indicator that more is there (peek effect)
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
                // Info Area
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
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
                            color: (isDark ? AppColors.darkText : AppColors.charcoal)
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(file.lastModifiedSync()),
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 10,
                              color: (isDark ? AppColors.darkText : AppColors.charcoal)
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
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Scan Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _RecentScanCard extends StatelessWidget {
  final File file;
  final bool isDark;

  const _RecentScanCard({required this.file, required this.isDark});

  String _formatDate(DateTime dt) =>
      DateFormat('dd MMM yyyy').format(dt);

  String _shortName(String name) {
    if (name.length > 20) return '${name.substring(0, 18)}…';
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final stat = file.statSync();
    final name = file.uri.pathSegments.last;
    final modDate = stat.modified;
    final isPdf = name.toLowerCase().endsWith('.pdf');

    return GestureDetector(
      onTap: () {
        // Open PDF viewer
        final doc = DocumentModel(
          id: file.path,
          categoryId: 'scan',
          yearLabel: DateFormat('yyyy').format(modDate),
          yearStart: modDate.year,
          fileName: name,
          filePath: file.path,
          pageCount: 1,
          uploadedAt: modDate,
        );
        context.push(
          '/categories/sub/scan/years/pdf',
          extra: {
            'document': doc,
            'categoryColor': AppColors.navyDark,
            'categoryName': 'Recent Scans',
          },
        );
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail area
            Container(
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.navyDark.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Center(
                child: Icon(
                  isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.image_rounded,
                  size: 36,
                  color: AppColors.navyDark.withValues(alpha: 0.6),
                ),
              ),
            ),

            // Info area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _shortName(name),
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.charcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(modDate),
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 9,
                            color: AppColors.charcoal.withValues(alpha: 0.45),
                          ),
                        ),
                        // Edit button
                        GestureDetector(
                          onTap: () => _openForEdit(context, name),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 13,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openForEdit(BuildContext context, String fileName) {
    // Navigate to scan review screen with the existing PDF path
    context.push(
      '/dashboard/add/review',
      extra: {
        'pageCount': 1,
        'source': 'existing_pdf',
        'imagePaths': <String>[],
        'existingPdfPath': file.path,
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Box Widget
// ─────────────────────────────────────────────────────────────────────────────
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
            style: (isDark
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
