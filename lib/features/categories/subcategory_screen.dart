// lib/features/categories/subcategory_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/constants/supabase_constants.dart';
import 'package:gda_vault_ai/core/services/supabase_service.dart';
import 'package:gda_vault_ai/models/category_model.dart';

class SubcategoryScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final Color categoryColor;

  const SubcategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
  final _supa = SupabaseService.instance;
  bool _isLoading = true;
  List<CategoryModel> _subCategories = const [];

  @override
  void initState() {
    super.initState();
    _loadSubCategories();
  }

  Future<void> _loadSubCategories() async {
    setState(() => _isLoading = true);
    try {
      final rows = await _supa.getSubCategories(widget.categoryId);
      final subCats = rows.map(CategoryModel.fromMap).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (!mounted) return;
      setState(() {
        _subCategories = subCats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading subcategories: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppColors.navyDark, AppColors.navyDark.withValues(alpha: 0.8)]
                    : [AppColors.navyDark, AppColors.navyLight],
              ),
            ),
          ),
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          title: Column(
            children: [
              Text(
                widget.categoryName,
                style: AppTextStyles.playfairDisplay.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "Select sub-category",
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          color: AppColors.gold,
          onRefresh: _loadSubCategories,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ParentCategoryHeroBanner(
                  categoryName: widget.categoryName,
                  categoryColor: widget.categoryColor,
                ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.97, 0.97)),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                  child: Text(
                    "Sub-categories",
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (isDark ? Colors.white : AppColors.charcoal).withValues(alpha: 0.5),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                  )
                else if (_subCategories.isEmpty)
                  _buildEmptyState(isDark)
                else
                  ..._subCategories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final sub = entry.value;
                    return _SubCategoryCard(
                      categoryColor: sub.color,
                      docCount: sub.docCount,
                      yearRange: sub.yearRange,
                      firstYear: sub.yearFrom?.toString() ?? "N/A",
                      lastYear: sub.yearTo?.toString() ?? "Now",
                      yearCount: _calculateYearCount(sub),
                      subCategoryFullName: sub.name,
                      description: "Official documents for ${sub.name}",
                      shortTag: sub.slug.toUpperCase(),
                      onTap: () {
                        context.push(
                          '/categories/sub/${sub.id}/years',
                          extra: {
                            'categoryName': widget.categoryName,
                            'subCategoryName': sub.name,
                            'categoryColor': sub.color,
                            'yearFrom': sub.yearFrom ?? 1961,
                            'yearTo': sub.yearTo,
                            'subCategoryId': sub.id,
                          },
                        );
                      },
                    ).animate(delay: (100 * index).ms).fadeIn().slideY(begin: 0.05);
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _calculateYearCount(CategoryModel sub) {
    if (sub.yearFrom == null) return "Unknown";
    final to = sub.yearTo ?? DateTime.now().year;
    final diff = to - sub.yearFrom! + 1;
    return "$diff years";
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 48,
              color: (isDark ? Colors.white : AppColors.charcoal).withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              "No sub-categories found",
              style: AppTextStyles.playfairDisplay.copyWith(
                fontSize: 18,
                color: (isDark ? Colors.white : AppColors.charcoal).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentCategoryHeroBanner extends StatelessWidget {
  final String categoryName;
  final Color categoryColor;
  const _ParentCategoryHeroBanner({required this.categoryName, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [categoryColor, categoryColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.gavel_rounded,
                      size: 18,
                      color: AppColors.gdaGold,
                    ),
                    AppSpacing.horizontal(8),
                    Text(
                      "BOARD OF AUTHORITY",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 10,
                        color: AppColors.gdaGold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vertical(8),
                Text(
                  categoryName,
                  style: AppTextStyles.playfairDisplay.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                AppSpacing.vertical(4),
                Text(
                  "Tap a sub-category below to browse documents",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.gavel_rounded,
              size: 28,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubCategoryCard extends StatelessWidget {
  final Color categoryColor;
  final int docCount;
  final String yearRange;
  final String firstYear;
  final String lastYear;
  final String yearCount;
  final String subCategoryFullName;
  final String description;
  final String shortTag;
  final VoidCallback onTap;

  const _SubCategoryCard({
    required this.categoryColor,
    required this.docCount,
    required this.yearRange,
    required this.firstYear,
    required this.lastYear,
    required this.yearCount,
    required this.subCategoryFullName,
    required this.description,
    required this.shortTag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.brightness == Brightness.dark 
              ? categoryColor.withValues(alpha: 0.3) 
              : AppColors.divider, 
          width: 1
        ),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.25)
                : categoryColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Tag(label: shortTag, color: categoryColor),
                              AppSpacing.horizontal(8),
                              _Tag(
                                label: yearRange,
                                color: AppColors.gdaGold,
                                isLight: true,
                              ),
                            ],
                          ),
                          AppSpacing.vertical(10),
                          Text(
                            subCategoryFullName,
                            style: AppTextStyles.playfairDisplay.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          AppSpacing.vertical(6),
                          Text(
                            description,
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.5),
                            ),
                            maxLines: 2,
                          ),
                          AppSpacing.vertical(12),
                          Row(
                            children: [
                              Icon(
                                Icons.folder_copy_rounded,
                                size: 13,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.4),
                              ),
                              AppSpacing.horizontal(4),
                              Text(
                                "$docCount documents",
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 11,
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.5),
                                ),
                              ),
                              AppSpacing.horizontal(16),
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.4),
                              ),
                              AppSpacing.horizontal(4),
                              Text(
                                yearCount,
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 11,
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.horizontal(12),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.9) : categoryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                height: 36,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.1),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Earliest: $firstYear",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.timeline_rounded,
                      size: 14,
                      color: categoryColor.withValues(alpha: 0.4),
                    ),
                    Text(
                      "Latest: $lastYear",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.5,
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
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final bool isLight;

  const _Tag({required this.label, required this.color, this.isLight = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark 
            ? color.withValues(alpha: 0.2)
            : (isLight ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? color.withValues(alpha: 0.3) : Colors.transparent,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.dmSans.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white.withValues(alpha: 0.95) : color,
          letterSpacing: isLight ? 0.0 : 1.0,
        ),
      ),
    );
  }
}
