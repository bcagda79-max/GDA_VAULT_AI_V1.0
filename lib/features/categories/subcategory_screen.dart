// lib/features/categories/subcategory_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class SubcategoryScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const SubcategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.navyDark,
          leading: const BackButton(color: Colors.white),
          title: Column(
            children: [
              Text(
                categoryName,
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
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ParentCategoryHeroBanner(categoryName: categoryName)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(begin: const Offset(0.97, 0.97)),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Text(
                  "Sub-categories",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              _SubCategoryCard(
                categoryColor: AppColors.catBoard,
                docCount: 248,
                yearRange: "1996–2026",
                firstYear: "1996",
                lastYear: "2026",
                yearCount: "31 years",
                subCategoryFullName: "Board of Authority Minutes 1996–2026",
                description:
                    "Annual board meeting minutes, resolutions and decisions",
                shortTag: "MINUTES",
                onTap: () {
                  context.push(
                    '/categories/sub/board-authority/years',
                    extra: {
                      'categoryName': "Board of Authority",
                      'subCategoryName': "Board of Authority Minutes 1996–2026",
                      'categoryColor': AppColors.catBoard,
                      'yearFrom': 1996,
                      'yearTo': 2026,
                    },
                  );
                },
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.05),
              _SubCategoryCard(
                categoryColor: AppColors.catTrust,
                docCount: 412,
                yearRange: "1961–1996",
                firstYear: "1961",
                lastYear: "1996",
                yearCount: "36 years",
                subCategoryFullName: "Trust Minutes 1961–1996",
                description:
                    "Historical trust records and land allocation documents",
                shortTag: "TRUST",
                onTap: () {
                  context.push(
                    '/categories/sub/trust-minutes/years',
                    extra: {
                      'categoryName': "Board of Authority",
                      'subCategoryName': "Trust Minutes 1961–1996",
                      'categoryColor': AppColors.catTrust,
                      'yearFrom': 1961,
                      'yearTo': 1996,
                    },
                  );
                },
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentCategoryHeroBanner extends StatelessWidget {
  final String categoryName;
  const _ParentCategoryHeroBanner({required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.catBoard, Color(0xFF0D1B3E)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gdaGold.withValues(alpha: 0.2), width: 1),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                        color: categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: categoryColor,
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
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
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
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLight ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.dmSans.copyWith(
          fontSize: 9,
          fontWeight: isLight ? FontWeight.normal : FontWeight.bold,
          color: isLight ? color : color,
          letterSpacing: isLight ? 0.0 : 1.0,
        ),
      ),
    );
  }
}
