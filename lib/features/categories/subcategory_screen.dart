// lib/features/categories/subcategory_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
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
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
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
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
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
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.categoryName,
                            style: AppTextStyles.playfairDisplay.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Select sub-category",
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.6),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          elevation: 0,
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
                    )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .scale(begin: const Offset(0.97, 0.97)),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    top: 8.0,
                    bottom: 8.0,
                  ),
                  child: Text(
                    "Sub-categories",
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (isDark ? Colors.white : AppColors.charcoal)
                          .withValues(alpha: 0.5),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
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
                        )
                        .animate(delay: (100 * index).ms)
                        .fadeIn()
                        .slideY(begin: 0.05);
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
              color: (isDark ? Colors.white : AppColors.charcoal).withValues(
                alpha: 0.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "No sub-categories found",
              style: AppTextStyles.playfairDisplay.copyWith(
                fontSize: 18,
                color: (isDark ? Colors.white : AppColors.charcoal).withValues(
                  alpha: 0.6,
                ),
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
  const _ParentCategoryHeroBanner({
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 20, 6, 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [categoryColor, categoryColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.folder_shared_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  "MAIN CATEGORY",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 9,
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                categoryName,
                style: AppTextStyles.playfairDisplay.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Explore specific archives within this family",
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 0.2,
                ),
              ),
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2638) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? categoryColor.withValues(alpha: 0.25)
              : AppColors.divider.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(22.0),
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
                              const SizedBox(width: 8),
                              _Tag(
                                label: yearRange,
                                color: AppColors.gold,
                                isLight: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            subCategoryFullName,
                            style: AppTextStyles.playfairDisplay.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.navyDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : AppColors.charcoal.withValues(alpha: 0.5),
                              height: 1.5,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Icon(
                                Icons.description_rounded,
                                size: 14,
                                color: AppColors.gold.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "$docCount Documents",
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : AppColors.charcoal.withValues(
                                          alpha: 0.7,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Icon(
                                Icons.history_rounded,
                                size: 14,
                                color: AppColors.gold.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                yearCount,
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : AppColors.charcoal.withValues(
                                          alpha: 0.7,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: categoryColor.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 28,
                        color: categoryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : categoryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : categoryColor.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "EARLIEST: $firstYear",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppColors.charcoal.withValues(alpha: 0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Icon(
                      Icons.timeline_rounded,
                      size: 16,
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                    Text(
                      "LATEST: $lastYear",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppColors.charcoal.withValues(alpha: 0.5),
                        letterSpacing: 0.5,
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
            ? color.withValues(alpha: 0.15)
            : (isLight
                  ? color.withValues(alpha: 0.1)
                  : color.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.dmSans.copyWith(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
