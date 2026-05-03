import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/services/supabase_service.dart';
import 'package:gda_vault_ai/models/category_model.dart';
import 'package:shimmer/shimmer.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _supa = SupabaseService.instance;
  bool _isLoading = true;
  List<CategoryModel> _topCategories = const [];
  final Map<String, int> _subCountByParent = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<bool> _hasInternet() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    if (!await _hasInternet()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final rows = await _supa.getAllCategories();
      final all = rows.map(CategoryModel.fromMap).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final subCountMap = <String, int>{};
      final docCountMap = <String, int>{};

      // First pass: identify children and their counts
      for (final cat in all) {
        if (cat.parentId != null) {
          subCountMap[cat.parentId!] = (subCountMap[cat.parentId!] ?? 0) + 1;
        }
        // Store individual counts
        docCountMap[cat.id] = cat.docCount;
      }

      if (!mounted) return;
      setState(() {
        _subCountByParent
          ..clear()
          ..addAll(subCountMap);

        _topCategories = all.where((category) => category.parentId == null).map(
          (category) {
            // Aggregate counts: parent count + all its children's counts
            int aggregatedDocCount = category.docCount;
            final children = all.where((c) => c.parentId == category.id);
            for (final child in children) {
              aggregatedDocCount += child.docCount;
            }

            return category.copyWith(
              hasSubCategories: subCountMap.containsKey(category.id),
              docCount: aggregatedDocCount,
            );
          },
        ).toList();
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
        backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
        body: Stack(
          children: [
            Positioned(
              top: -80,
              left: -60,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: isDark ? 0.12 : 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 300,
              right: -80,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.navyLight.withValues(
                          alpha: isDark ? 0.1 : 0.04,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF161E35), const Color(0xFF0A0F1E)]
                          : [AppColors.navyDark, AppColors.navyMid],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Text(
                          'ARCHIVE VAULT',
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.gold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Categories',
                          style: AppTextStyles.playfairDisplay.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_stories_rounded,
                                      size: 16,
                                      color: AppColors.gold,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${_topCategories.length} Main Families',
                                      style: AppTextStyles.dmSans.copyWith(
                                        fontSize: 12,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '$totalDocs Files',
                                  style: AppTextStyles.dmSans.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.gold,
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
                ),
                Expanded(
                  child: _isLoading
                      ? _CategoriesLoadingList(isDark: isDark)
                      : _topCategories.isEmpty
                      ? _CategoriesEmptyState(
                          isDark: isDark,
                          onRetry: _loadCategories,
                        )
                      : RefreshIndicator(
                          color: AppColors.gold,
                          onRefresh: _loadCategories,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(8, 14, 8, 18),
                            children: [
                              _buildSectionHeader(
                                context,
                                isDark,
                                title: 'Folders',
                                subtitle: '',
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(_topCategories.length, (index) {
                                final category = _topCategories[index];
                                return _buildCategoryItem(
                                  context,
                                  category,
                                  index,
                                  isDark,
                                  subCount: _subCountByParent[category.id] ?? 0,
                                );
                              }),
                            ],
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

  Widget _buildSectionHeader(
    BuildContext context,
    bool isDark, {
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gold,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.navyDark.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.navyDark.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_topCategories.length} Families',
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.navyDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    CategoryModel category,
    int index,
    bool isDark, {
    required int subCount,
  }) {
    return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1E2638),
                      category.color.withValues(alpha: 0.2),
                    ]
                  : [category.color, category.color.withValues(alpha: 0.85)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? category.color.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _navigateToCategory(context, category),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.15),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        category.iconData,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: AppTextStyles.playfairDisplay.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (category.hasSubCategories)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.gold.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '$subCount SUB',
                                    style: AppTextStyles.dmSans.copyWith(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.gold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category.yearRange,
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              Container(
                                width: 3,
                                height: 3,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Icon(
                                Icons.description_rounded,
                                size: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${category.docCount} Files',
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: (category.docCount / 500.0).clamp(
                                0.05,
                                1.0,
                              ),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.gold,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: index * 70))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.03, end: 0, duration: 300.ms);
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
}

class _CategoriesLoadingList extends StatelessWidget {
  final bool isDark;
  const _CategoriesLoadingList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark
          ? AppColors.darkCard.withValues(alpha: 0.92)
          : AppColors.divider.withValues(alpha: 0.55),
      highlightColor: isDark ? AppColors.darkSurface : Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 108,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider, width: 0.8),
          ),
        ),
      ),
    );
  }
}

class _CategoriesEmptyState extends StatelessWidget {
  final bool isDark;
  final Future<void> Function() onRetry;

  const _CategoriesEmptyState({required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.navyDark.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 34,
                color: (isDark ? AppColors.darkText : AppColors.charcoal)
                    .withValues(alpha: 0.28),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No categories available',
              style: AppTextStyles.playfairDisplay.copyWith(
                fontSize: 18,
                color: (isDark ? AppColors.darkText : AppColors.charcoal)
                    .withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 12,
                color: (isDark ? AppColors.darkText : AppColors.charcoal)
                    .withValues(alpha: 0.48),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppColors.navyDark.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: TextButton(
                onPressed: onRetry,
                child: Text(
                  'Retry',
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 13,
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
