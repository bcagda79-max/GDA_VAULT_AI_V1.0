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

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rows = await _supa.getAllCategories();
      final rawAll = rows.map(CategoryModel.fromMap).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      // Override 0 counts by querying documents table counts dynamically
      final countsFutures = rawAll.map((cat) async {
        try {
          final countRes = await _supa.client
              .from('documents')
              .select('id')
              .or('category.eq.${cat.id},sub_category.eq.${cat.id}');
          return cat.copyWith(docCount: (countRes as List).length);
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(76.0),
          child: AppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppColors.darkSurface, AppColors.darkBg]
                      : [AppColors.navyDark, AppColors.navyMid],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Space for alignment if needed, or back button
                      const SizedBox(width: 40),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Categories',
                                style: AppTextStyles.playfairDisplay.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'All Library Files',
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),
            ),
            elevation: 0,
          ),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_copy_rounded,
                        size: 14,
                        color: AppColors.catBoard,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'All Files · ${_topCategories.length} Categories',
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 12,
                          color:
                              (isDark ? AppColors.darkText : AppColors.charcoal)
                                  .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.catBoard.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalDocs Documents',
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.catBoard,
                      ),
                    ),
                  ),
                ],
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
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        itemCount: _topCategories.length,
                        itemBuilder: (context, index) {
                          final category = _topCategories[index];
                          return _buildCategoryItem(
                            context,
                            category,
                            index,
                            isDark,
                            subCount: _subCountByParent[category.id] ?? 0,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
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
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? AppColors.darkCard : AppColors.navyDark,
                category.color.withValues(alpha: 0.78),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gdaGold.withValues(alpha: 0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.white.withValues(alpha: 0.08),
              onTap: () => _navigateToCategory(context, category),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.gdaGold.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          category.iconData,
                          size: 22,
                          color: AppColors.gdaGold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: AppTextStyles.dmSans.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 14),
                                  child: Row(
                                    children: [
                                      if (category.hasSubCategories)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.14,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '$subCount sub',
                                            style: AppTextStyles.dmSans
                                                .copyWith(
                                                  fontSize: 8,
                                                  color: Colors.white,
                                                ),
                                          ),
                                        ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  category.yearRange,
                                  style: AppTextStyles.dmSans.copyWith(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.78),
                                  ),
                                ),
                                Container(
                                  width: 3,
                                  height: 3,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  '${category.docCount} files',
                                  style: AppTextStyles.dmSans.copyWith(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.78),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: (category.docCount / 500.0).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.16,
                                  ),
                                  valueColor: AlwaysStoppedAnimation(
                                    AppColors.gdaGold.withValues(alpha: 0.9),
                                  ),
                                  minHeight: 2.5,
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
          ? AppColors.darkCard.withValues(alpha: 0.9)
          : AppColors.divider.withValues(alpha: 0.6),
      highlightColor: isDark ? AppColors.darkSurface : Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 92,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
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
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: (isDark ? AppColors.darkText : AppColors.charcoal)
                  .withValues(alpha: 0.25),
            ),
            const SizedBox(height: 14),
            Text(
              'No categories available',
              style: AppTextStyles.playfairDisplay.copyWith(
                fontSize: 18,
                color: (isDark ? AppColors.darkText : AppColors.charcoal)
                    .withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 12,
                color: (isDark ? AppColors.darkText : AppColors.charcoal)
                    .withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
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
          ],
        ),
      ),
    );
  }
}
