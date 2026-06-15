import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/services/api_service.dart';
import 'package:gda_vault_ai/models/category_model.dart';
import 'package:shimmer/shimmer.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _api = ApiService.instance;
  bool _isLoading = true;
  List<CategoryModel> _topCategories = const [];
  final Map<String, int> _subCountByParent = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rows = await _api.getAllCategories();
      final rawAll = rows.map(CategoryModel.fromMap).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      // Override 0 counts by querying documents table counts dynamically
      final countsFutures = rawAll.map((cat) async {
        try {
          final docs = await _api.getDocumentsByCategory(cat.id);
          return cat.copyWith(docCount: docs.length);
        } catch (e) {
          return cat;
        }
      });

      final all = await Future.wait(countsFutures);

      final counts = <String, int>{};
      for (final category in all) {
        final parentId = category.parentId;
        if (parentId == null) continue;
        counts[parentId] = (counts[parentId] ?? 0) + 1;
      }

      if (!mounted) return;
      setState(() {
        _subCountByParent
          ..clear()
          ..addAll(counts);
        _topCategories = all
            .where((category) => category.parentId == null)
            .map(
              (category) => category.copyWith(
                hasSubCategories: counts.containsKey(category.id),
              ),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _topCategories = const [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load categories'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToCategory(BuildContext context, CategoryModel cat) {
    if (cat.hasSubCategories) {
      context.push(
        '/categories/sub/${cat.id}',
        extra: {'categoryName': cat.name, 'categoryColor': cat.color},
      );
      return;
    }

    context.push(
      '/categories/sub/${cat.id}/years',
      extra: {
        'categoryName': cat.name,
        'categoryColor': cat.color,
        'yearFrom': cat.yearFrom ?? 1961,
        'yearTo': cat.yearTo,
        'subCategoryName': null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalDocs = _topCategories.fold<int>(
      0,
      (sum, item) => sum + item.docCount,
    );

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: isDark ? AppTokens.darkBgPage : AppTokens.lightBgPage,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 860;
            final useGrid = constraints.maxWidth > 1100;

            return Column(
              children: [
                // HEADER
                if (!isDesktop) _buildMobileHeader(isDark, totalDocs),
                if (isDesktop) _buildDesktopHeader(isDark),

                // STATS ROW (mobile only)
                if (!isDesktop) _buildStatsRow(isDark),

                // CATEGORY LIST
                Expanded(
                  child: _isLoading
                      ? _CategoriesLoadingList(isDark: isDark)
                      : _topCategories.isEmpty
                          ? _CategoriesEmptyState(
                              isDark: isDark,
                              onRetry: _loadCategories,
                            )
                          : RefreshIndicator(
                              color: isDark
                                  ? AppTokens.darkBrandPrimary
                                  : AppTokens.lightBrandPrimary,
                              onRefresh: _loadCategories,
                              child: useGrid
                                  ? _buildGridView(isDark)
                                  : _buildListView(isDark, isDesktop),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── MOBILE HEADER ──────────────────────────────────────
  Widget _buildMobileHeader(bool isDark, int totalDocs) {
    return Container(
      height: 56,
      color: isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CATEGORIES',
                    style: AppTextStyles.labelSm.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Text(
                    'All Library Files',
                    style: AppTextStyles.labelSm.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8899B0),
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  // ── DESKTOP HEADER ─────────────────────────────────────
  Widget _buildDesktopHeader(bool isDark) {
    final textTertiary =
        isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final textPrimary =
        isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary;
    final textSecondary =
        isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              Icon(Icons.grid_view_outlined, size: 14, color: textTertiary),
              const SizedBox(width: 6),
              Text(
                'Categories',
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 13,
                  color: textTertiary,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Document Categories',
            style: AppTextStyles.headingLg.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Browse all official GDA document archives',
            style: AppTextStyles.bodyMd.copyWith(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── STATS ROW (mobile) ─────────────────────────────────
  Widget _buildStatsRow(bool isDark) {
    final bgSurface =
        isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight =
        isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final textSecondary =
        isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary =
        isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final shadowXs = isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowXs;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: bgSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderLight, width: 1),
                boxShadow: shadowXs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_outlined, size: 14, color: textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    '${_topCategories.length} Categories',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: bgSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderLight, width: 1),
                boxShadow: shadowXs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined,
                      size: 14, color: textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    '${_topCategories.fold<int>(0, (s, c) => s + c.docCount)} Documents',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LIST VIEW ──────────────────────────────────────────
  Widget _buildListView(bool isDark, bool isDesktop) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: 8,
      ),
      itemCount: _topCategories.length,
      itemBuilder: (context, index) {
        final category = _topCategories[index];
        final subCount = _subCountByParent[category.id] ?? 0;
        return _buildCategoryRow(category, index, isDark, subCount)
            .animate(delay: Duration(milliseconds: index * 80))
            .fadeIn(duration: 250.ms)
            .slideY(begin: 0.04, end: 0, curve: Curves.easeOut);
      },
    );
  }

  // ── GRID VIEW (Desktop > 1100px) ───────────────────────
  Widget _buildGridView(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 12,
        mainAxisExtent: 72,
      ),
      itemCount: _topCategories.length,
      itemBuilder: (context, index) {
        final category = _topCategories[index];
        final subCount = _subCountByParent[category.id] ?? 0;
        return _buildCategoryRow(category, index, isDark, subCount)
            .animate(delay: Duration(milliseconds: index * 80))
            .fadeIn(duration: 250.ms)
            .slideY(begin: 0.04, end: 0, curve: Curves.easeOut);
      },
    );
  }

  // ── CATEGORY ROW ITEM ──────────────────────────────────
  Widget _buildCategoryRow(
      CategoryModel category, int index, bool isDark, int subCount) {
    final bgSurface =
        isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight =
        isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final textPrimary =
        isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary;
    final textSecondary =
        isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary =
        isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final brandPrimary =
        isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;
    final brandSurface =
        isDark ? AppTokens.darkBrandSurface : AppTokens.lightBrandSurface;
    final shadowXs = isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowXs;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          onTap: () => _navigateToCategory(context, category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
              boxShadow: shadowXs,
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: brandSurface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Icon(
                    Icons.folder_outlined,
                    size: 18,
                    color: brandPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                // Title + details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.name,
                        style: AppTextStyles.headingSm.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            'All years',
                            style: AppTextStyles.bodySm.copyWith(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '•',
                              style: AppTextStyles.bodySm.copyWith(
                                fontSize: 12,
                                color: textTertiary,
                              ),
                            ),
                          ),
                          Text(
                            '${category.docCount} files',
                            style: AppTextStyles.bodySm.copyWith(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Sub count chip
                if (subCount > 0) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: brandSurface,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusSm),
                      border: Border.all(color: borderLight, width: 1),
                    ),
                    child: Text(
                      '$subCount sub',
                      style: AppTextStyles.labelSm.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: brandPrimary,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.chevron_right, size: 18, color: textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── LOADING SHIMMER ────────────────────────────────────
class _CategoriesLoadingList extends StatelessWidget {
  final bool isDark;
  const _CategoriesLoadingList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark
          ? AppTokens.darkBorderLight
          : AppTokens.lightBorderLight.withValues(alpha: 0.6),
      highlightColor: isDark ? AppTokens.darkBgSurface : Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 66,
          decoration: BoxDecoration(
            color: isDark ? AppTokens.darkBgSurface : Colors.white,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(
                color: isDark
                    ? AppTokens.darkBorderLight
                    : AppTokens.lightBorderLight,
                width: 1),
          ),
        ),
      ),
    );
  }
}

// ── EMPTY STATE ────────────────────────────────────────
class _CategoriesEmptyState extends StatelessWidget {
  final bool isDark;
  final Future<void> Function() onRetry;

  const _CategoriesEmptyState({required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary =
        isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final brandPrimary =
        isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No categories available',
              style: AppTextStyles.headingSm.copyWith(
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 13,
                color: textTertiary,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 13,
                  color: brandPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
