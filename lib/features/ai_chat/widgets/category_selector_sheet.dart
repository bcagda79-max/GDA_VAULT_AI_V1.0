import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_state.dart';
import '../providers/chat_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class CategorySelectorSheet extends ConsumerWidget {
  const CategorySelectorSheet({super.key});

  String _getCatDocCount(String id) {
    // Mock counts for realism
    switch (id) {
      case 'board-authority':
        return "452";
      case 'town-plots':
        return "1,284";
      case 'administration':
        return "89";
      case 'private-properties':
        return "215";
      case 'trust-minutes':
        return "342";
      default:
        return "0";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCount = chatState.selectedCategories.length;
    final selectedCatNames = chatState.selectedCategories
        .map((c) => c.shortName)
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.charcoal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Search Categories",
                      style: AppTextStyles.playfairDisplay.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkText : AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Select which archives to search",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 12,
                        color: AppColors.charcoal.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navyDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Done",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          // Select All / Clear
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$selectedCount of 5 selected",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 12,
                    color: AppColors.charcoal.withValues(alpha: 0.5),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          ref.read(chatProvider.notifier).selectAllCategories(),
                      child: Text(
                        "Select All",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "·",
                      style: TextStyle(
                        color: AppColors.charcoal.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () =>
                          ref.read(chatProvider.notifier).clearAllCategories(),
                      child: Text(
                        "Clear",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 11,
                          color: AppColors.charcoal.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Category List (scrollable to avoid overflow on small screens)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: chatState.categories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: _buildCategoryRow(ref, cat),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Search Scope Summary
                  if (selectedCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 20,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.navyDark.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.divider,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 14,
                              color: AppColors.charcoal.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Searching across $selectedCount ${selectedCount == 1 ? 'category' : 'categories'}: $selectedCatNames",
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 11,
                                  color: AppColors.charcoal.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(WidgetRef ref, ChatCategory cat) {
    return GestureDetector(
      onTap: () => ref.read(chatProvider.notifier).toggleCategory(cat.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cat.isSelected
              ? cat.color.withValues(alpha: 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cat.isSelected
                ? cat.color.withValues(alpha: 0.3)
                : AppColors.divider,
            width: cat.isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cat.color.withValues(
                  alpha: cat.isSelected ? 0.15 : 0.08,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  cat.icon,
                  size: 20,
                  color: cat.color.withValues(
                    alpha: cat.isSelected ? 1.0 : 0.6,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 14,
                      fontWeight: cat.isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: cat.isSelected
                          ? AppColors.charcoal
                          : AppColors.charcoal.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${cat.shortName} · ${_getCatDocCount(cat.id)} docs",
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 10,
                      color: AppColors.charcoal.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cat.isSelected ? cat.color : Colors.transparent,
                border: Border.all(
                  color: cat.isSelected ? cat.color : AppColors.divider,
                  width: 2,
                ),
              ),
              child: cat.isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
