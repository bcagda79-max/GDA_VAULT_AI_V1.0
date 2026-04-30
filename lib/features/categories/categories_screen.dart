// lib/features/categories/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/data/mock_data.dart';
import 'package:gda_vault_ai/models/category_model.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = MockData.categories.where((c) => c.parentId == null).toList();
    final totalDocs = categories.fold<int>(0, (sum, item) => sum + item.docCount);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
        body: Column(
          children: [
            // CATEGORIES HEADER (merges visually with HomeAppBar)
            Container(
              width: double.infinity,
              color: AppColors.navyDark,
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Text(
                    "Categories",
                    style: AppTextStyles.playfairDisplay.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "All Files",
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            Container(color: AppColors.gold.withValues(alpha: 0.25), height: 0.8),
            // TOP INFO BAR
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
                        "All Files · ${categories.length} Categories",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 12,
                          color: (isDark ? AppColors.darkText : AppColors.charcoal)
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.catBoard.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$totalDocs Documents",
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
            // CATEGORY LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryItem(context, categories[index], index, isDark);
                },
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
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: category.color.withValues(alpha: 0.08),
          onTap: () => _navigateToCategory(context, category),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // LEFT COLOR STRIPE
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
                // ICON
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(category.iconData, size: 22, color: category.color),
                  ),
                ),
                // CONTENT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + arrow row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                category.name,
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkText
                                      : AppColors.charcoal,
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
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "2 sub",
                                        style: AppTextStyles.dmSans.copyWith(
                                          fontSize: 8,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                    ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 13,
                                    color: AppColors.charcoal.withValues(alpha: 0.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Year range + doc count
                        Row(
                          children: [
                            Text(
                              category.yearRange ?? "N/A",
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: 11,
                                color: AppColors.charcoal.withValues(alpha: 0.4),
                              ),
                            ),
                            Container(
                              width: 3,
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: AppColors.charcoal.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              "${category.docCount} files",
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: 11,
                                color: AppColors.charcoal.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Progress bar
                        Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: (category.docCount / 500.0).clamp(0.0, 1.0),
                              backgroundColor: category.color.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation(
                                category.color.withValues(alpha: 0.4),
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
        extra: {
          'categoryName': cat.name,
          'categoryColor': cat.color,
        },
      );
    } else {
      context.push(
        '/categories/sub/${cat.id}/years',
        extra: {
          'categoryName': cat.name,
          'categoryColor': cat.color,
          'yearFrom': int.tryParse(cat.yearRange?.split(' – ').first ?? '1961') ?? 1961,
          'yearTo': cat.yearRange?.contains('Ongoing') == true ? null : int.tryParse(cat.yearRange?.split(' – ').last ?? ''),
          'subCategoryName': null,
        },
      );
    }
  }
}
