import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/models/document_model.dart';

class DesktopHomeTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(36, 28, 36, 36),
        child: Column(
          children: [
            // SECTION 1: Command Bar (Using the stable 2-column Expanded row)
            _buildCommandBar(
              context,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.03, end: 0),

            const SizedBox(height: 24),

            // SECTION 2: Hero Stats Row
            _buildStatsRow().animate().fadeIn(delay: 100.ms, duration: 400.ms),

            const SizedBox(height: 28),

            // SECTION 3: Main Content Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildLeftPanel(
                    context,
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: _buildRecentDocs(context)
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideX(begin: 0.03, end: 0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1528) : const Color(0xFF0D1B3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC5A059).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                    const SizedBox(width: 8),
                    const Text(
                      "SECURE SESSION ACTIVE",
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  getGreeting(),
                  style: AppTextStyles.playfairDisplay.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Galiyat Development Authority — Document Intelligence Platform",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF6B82AA),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Right: Date & Logo
          Row(
            children: [
              Text(
                getFormattedDate(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC5A059),
                ),
              ),
              const SizedBox(width: 24),
              Image.asset(
                'assets/images/gda_logo.png',
                width: 64, // Bigger logo
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.account_balance_rounded,
                  size: 48,
                  color: Color(0xFFC5A059),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    if (statsLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildStatBoxWrapper(
            _StatBoxDesktop(
              title: 'TOTAL DOCS',
              value: formatTotalDocs(stats['total_documents']),
              icon: Icons.description_rounded,
              statColor: const Color(0xFFC5A059),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 16),
          _buildStatBoxWrapper(
            _StatBoxDesktop(
              title: 'PAGES SCANNED',
              value: formatTotalPages(stats['total_pages']),
              icon: Icons.auto_stories_rounded,
              statColor: const Color(0xFF22C55E),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 16),
          _buildStatBoxWrapper(
            _StatBoxDesktop(
              title: 'CATEGORIES',
              value: '${stats['category_count'] ?? 0}',
              icon: Icons.folder_special_rounded,
              statColor: const Color(0xFF3B82F6),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 16),
          _buildStatBoxWrapper(
            _StatBoxDesktop(
              title: 'STORAGE (GB)',
              value: (stats['total_size_gb'] as double? ?? 0.0).toStringAsFixed(
                2,
              ),
              icon: Icons.sd_storage_rounded,
              statColor: const Color(0xFF8B5CF6),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBoxWrapper(Widget child) {
    return Container(
      width: 240, // Fixed width for desktop to prevent squeezing
      child: child,
    );
  }

  Widget _buildLeftPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            "QUICK ACCESS",
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF4A6394) : const Color(0xFF94A3B8),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                title: 'Categories',
                subtitle: 'View folders & files',
                icon: Icons.folder_copy_rounded,
                tileColor: const Color(0xFF3B82F6),
                onTap: () => context.push('/categories'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionTile(
                title: 'Add New File',
                subtitle: 'Import or scan new',
                icon: Icons.document_scanner_rounded,
                tileColor: const Color(0xFF22C55E),
                onTap: () => context.go('/dashboard/add'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionTile(
                title: 'Offline Vault',
                subtitle: 'Access without internet',
                icon: Icons.cloud_off_rounded,
                tileColor: const Color(0xFF8B5CF6),
                onTap: () => context.push('/dashboard/offline-documents'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color tileColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1528) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3260) : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: tileColor),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: isDark
                      ? const Color(0xFF2D4070)
                      : const Color(0xFFCBD5E1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0D1B3E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF4A6394)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: tileColor.withValues(alpha: 0.3)),
            const SizedBox(height: 10),
            Text(
              "OPEN →",
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w700,
                color: tileColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDocs(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B1528) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            border: Border.all(
              color: isDark ? const Color(0xFF1E3260) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Top Accent
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC5A059),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                ),
              ),
              // Content
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 18,
                              color: Color(0xFFC5A059),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "RECENT SCANNED",
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFF4A6394)
                                      : const Color(0xFF94A3B8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () =>
                            context.push('/dashboard/recent-documents'),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: const Text(
                            "VIEW ALL →",
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFC5A059),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (recentOpenedLoading)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1528) : Colors.white,
              border: Border(
                left: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E3260)
                      : const Color(0xFFE2E8F0),
                ),
                right: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E3260)
                      : const Color(0xFFE2E8F0),
                ),
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E3260)
                      : const Color(0xFFEFF2F7),
                ),
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          )
        else if (recentlyOpened.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1528) : Colors.white,
              border: Border(
                left: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E3260)
                      : const Color(0xFFE2E8F0),
                ),
                right: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E3260)
                      : const Color(0xFFE2E8F0),
                ),
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E3260)
                      : const Color(0xFFEFF2F7),
                ),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: (isDark ? Colors.white : const Color(0xFF0D1B3E))
                        .withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent documents',
                    style: TextStyle(
                      fontSize: 14,
                      color: (isDark ? Colors.white : const Color(0xFF0D1B3E))
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentlyOpened
              .take(6)
              .map(
                (doc) => InkWell(
                  onTap: () => context.push('/categories/view', extra: doc),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0B1528) : Colors.white,
                      border: Border(
                        left: BorderSide(
                          color: isDark
                              ? const Color(0xFF1E3260)
                              : const Color(0xFFE2E8F0),
                        ),
                        right: BorderSide(
                          color: isDark
                              ? const Color(0xFF1E3260)
                              : const Color(0xFFE2E8F0),
                        ),
                        bottom: BorderSide(
                          color: isDark
                              ? const Color(0xFF1E3260)
                              : const Color(0xFFEFF2F7),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0D1B3E),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy, hh:mm a',
                                ).format(doc.uploadedAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? const Color(0xFF4A6394)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF2D4070)
                              : const Color(0xFFCBD5E1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

// Restoring the stable _StatBoxDesktop class that worked perfectly in iteration 1
class _StatBoxDesktop extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color statColor;
  final bool isDark;

  const _StatBoxDesktop({
    required this.title,
    required this.value,
    required this.icon,
    required this.statColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1528) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3260) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top Accent Line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: statColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF4A6394)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    Icon(
                      icon,
                      size: 16,
                      color: statColor.withValues(alpha: 0.7),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0D1B3E),
                      height: 1.0,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  width: 32,
                  decoration: BoxDecoration(
                    color: statColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
