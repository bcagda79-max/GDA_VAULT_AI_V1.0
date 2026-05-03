import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_state.dart';
import '../providers/chat_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class CategorySelectorSheet extends ConsumerWidget {
  const CategorySelectorSheet({super.key});

  String _formatCount(int count) {
    if (count >= 1000) {
      return "${(count / 1000).toStringAsFixed(1)}k";
    }
    return count.toString();
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
        color: isDark ? const Color(0xFF121A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.charcoal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SEARCH ARCHIVES",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Select Categories",
                        style: AppTextStyles.playfairDisplay.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.navyDark,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark 
                        ? Colors.white.withValues(alpha: 0.05) 
                        : AppColors.navyDark.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? Colors.white : AppColors.navyDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1.2,
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.divider.withValues(alpha: 0),
                  AppColors.divider.withValues(alpha: 0.8),
                  AppColors.divider.withValues(alpha: 0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),

          // Year Range Selector - Enhanced professional styling
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navyLight.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.navyLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          size: 13,
                          color: AppColors.navyLight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Select Year",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyLight,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildYearDropdown(
                        context,
                        ref,
                        label: "From Year",
                        value: chatState.yearFrom,
                        onChanged: (val) => ref
                            .read(chatProvider.notifier)
                            .updateYearRange(val, chatState.yearTo),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildYearDropdown(
                        context,
                        ref,
                        label: "To Year",
                        value: chatState.yearTo,
                        onChanged: (val) => ref
                            .read(chatProvider.notifier)
                            .updateYearRange(chatState.yearFrom, val),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                if (chatState.yearFrom != null || chatState.yearTo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: GestureDetector(
                      onTap: () => ref
                          .read(chatProvider.notifier)
                          .updateYearRange(null, null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navyLight.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.navyLight.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              size: 13,
                              color: AppColors.navyLight.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Clear Year Filter",
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navyLight.withValues(
                                  alpha: 0.9,
                                ),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Container(
            height: 1.2,
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.divider.withValues(alpha: 0),
                  AppColors.divider.withValues(alpha: 0.8),
                  AppColors.divider.withValues(alpha: 0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          // Category Selection Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navyLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.navyLight.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    "$selectedCount of 5 selected",
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyLight,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      ref.read(chatProvider.notifier).clearAllCategories(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.charcoal.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.charcoal.withValues(alpha: 0.1),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      "Clear All",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal.withValues(alpha: 0.7),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: chatState.categories
                          .where((c) => c.parentId == null)
                          .map((cat) {
                            final children = chatState.categories
                                .where((c) => c.parentId == cat.id)
                                .toList();
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: _buildCategoryRow(
                                    context,
                                    ref,
                                    cat,
                                    isDark,
                                  ),
                                ),
                                if (cat.isSelected && children.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      bottom: 10,
                                    ),
                                    child: Column(
                                      children: children.map((sub) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: _buildCategoryRow(
                                            context,
                                            ref,
                                            sub,
                                            isDark,
                                            isSub: true,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            );
                          })
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Scope Summary
                  if (selectedCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 28,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.navyLight.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.navyLight.withValues(alpha: 0.25),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navyLight.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.navyLight.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: AppColors.navyLight,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Search Scope",
                                    style: AppTextStyles.dmSans.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navyLight,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$selectedCount ${selectedCount == 1 ? 'category' : 'categories'}: $selectedCatNames",
                                    style: AppTextStyles.dmSans.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.75)
                                          : AppColors.charcoal.withValues(
                                              alpha: 0.75,
                                            ),
                                      height: 1.3,
                                    ),
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    WidgetRef ref,
    ChatCategory cat,
    bool isDark, {
    bool isSub = false,
  }) {
    // Calculate combined doc count for Board of Authority parent
    int displayDocCount = cat.docCount;
    if (cat.name.contains("Board of Authority") && cat.parentId == null) {
      final children = ref
          .watch(chatProvider)
          .categories
          .where((c) => c.parentId == cat.id)
          .toList();
      displayDocCount = children.fold(0, (sum, c) => sum + c.docCount);
    }

    return GestureDetector(
      onTap: () => ref.read(chatProvider.notifier).toggleCategory(cat.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSub ? 12 : 14,
          vertical: isSub ? 11 : 14,
        ),
        decoration: BoxDecoration(
          color: cat.isSelected
              ? cat.color.withValues(alpha: isDark ? 0.12 : 0.08)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cat.isSelected
                ? cat.color.withValues(alpha: isDark ? 0.45 : 0.3)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.divider),
            width: cat.isSelected ? 1.3 : 0.9,
          ),
          boxShadow: cat.isSelected
              ? [
                  BoxShadow(
                    color: cat.color.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  if (isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                ],
        ),
        child: Row(
          children: [
            // Category icon - enhanced styling
            Container(
              width: isSub ? 32 : 40,
              height: isSub ? 32 : 40,
              decoration: BoxDecoration(
                color: cat.color.withValues(
                  alpha: cat.isSelected ? (isDark ? 0.25 : 0.15) : 0.07,
                ),
                borderRadius: BorderRadius.circular(isSub ? 8 : 10),
              ),
              child: Center(
                child: Icon(
                  cat.icon,
                  size: isSub ? 16 : 20,
                  color: cat.color.withValues(
                    alpha: cat.isSelected ? 1.0 : 0.7,
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
                      fontSize: isSub ? 13 : 14,
                      fontWeight: cat.isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: cat.isSelected
                          ? (isDark ? Colors.white : AppColors.charcoal)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.65)
                                : AppColors.charcoal.withValues(alpha: 0.7)),
                      letterSpacing: cat.isSelected ? 0.1 : 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${cat.shortName} · ${_formatCount(displayDocCount)} docs",
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : AppColors.charcoal.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            // Checkbox - refined styling
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cat.isSelected ? cat.color : Colors.transparent,
                border: Border.all(
                  color: cat.isSelected ? cat.color : AppColors.divider,
                  width: cat.isSelected ? 2 : 1.5,
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

  Widget _buildYearDropdown(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String? value,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    final years = List.generate(
      2026 - 1960 + 1,
      (index) => (1960 + index).toString(),
    ).reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : AppColors.charcoal.withValues(alpha: 0.6),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppColors.divider,
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyLight.withValues(
                  alpha: isDark ? 0.05 : 0.06,
                ),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                "Select",
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : AppColors.charcoal.withValues(alpha: 0.4),
                  letterSpacing: 0.2,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: isDark
                    ? AppColors.navyLight.withValues(alpha: 0.6)
                    : AppColors.navyLight.withValues(alpha: 0.65),
              ),
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.95)
                    : AppColors.charcoal,
                letterSpacing: 0.2,
              ),
              dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              items: years
                  .map(
                    (y) => DropdownMenuItem(
                      value: y,
                      child: Text(
                        y,
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.95)
                              : AppColors.charcoal,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
