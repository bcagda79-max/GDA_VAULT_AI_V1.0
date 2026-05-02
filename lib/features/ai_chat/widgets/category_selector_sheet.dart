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
          
          // Year Range Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.gold),
                    const SizedBox(width: 6),
                    Text(
                      "Historical Time Window (Optional)",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildYearDropdown(
                        context,
                        ref,
                        label: "Year From",
                        value: chatState.yearFrom,
                        onChanged: (val) => ref.read(chatProvider.notifier).updateYearRange(val, chatState.yearTo),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildYearDropdown(
                        context,
                        ref,
                        label: "Year To",
                        value: chatState.yearTo,
                        onChanged: (val) => ref.read(chatProvider.notifier).updateYearRange(chatState.yearFrom, val),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                if (chatState.yearFrom != null || chatState.yearTo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: GestureDetector(
                      onTap: () => ref.read(chatProvider.notifier).updateYearRange(null, null),
                      child: Text(
                        "Clear Time Filter",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.catPrivate,
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
                          ref.read(chatProvider.notifier).clearAllCategories(),
                      child: Text(
                        "Clear Categories",
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
                              child: _buildCategoryRow(context, ref, cat, isDark),
                            ),
                            if (cat.isSelected && children.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 16, bottom: 10),
                                child: Column(
                                  children: children.map((sub) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: _buildCategoryRow(context, ref, sub, isDark, isSub: true),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
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
                              Icons.info_outline_rounded,
                              size: 14,
                              color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.charcoal.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Searching across $selectedCount ${selectedCount == 1 ? 'category' : 'categories'}: $selectedCatNames",
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 11,
                                  color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.charcoal.withValues(alpha: 0.55),
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

  Widget _buildCategoryRow(BuildContext context, WidgetRef ref, ChatCategory cat, bool isDark, {bool isSub = false}) {
    return GestureDetector(
      onTap: () => ref.read(chatProvider.notifier).toggleCategory(cat.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isSub ? 12 : 14, vertical: isSub ? 10 : 14),
        decoration: BoxDecoration(
          color: cat.isSelected
              ? cat.color.withValues(alpha: isDark ? 0.12 : 0.07)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cat.isSelected
                ? cat.color.withValues(alpha: isDark ? 0.5 : 0.3)
                : (isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.divider),
            width: cat.isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: isSub ? 32 : 40,
              height: isSub ? 32 : 40,
              decoration: BoxDecoration(
                color: cat.color.withValues(
                  alpha: cat.isSelected ? (isDark ? 0.25 : 0.15) : 0.08,
                ),
                borderRadius: BorderRadius.circular(isSub ? 8 : 10),
              ),
              child: Center(
                child: Icon(
                  cat.icon,
                  size: isSub ? 16 : 20,
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
                      fontSize: isSub ? 13 : 14,
                      fontWeight: cat.isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: cat.isSelected
                          ? (isDark ? Colors.white : AppColors.charcoal)
                          : (isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.charcoal.withValues(alpha: 0.7)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${cat.shortName} · ${_formatCount(cat.docCount)} docs",
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 9,
                      color: isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.charcoal.withValues(alpha: 0.4),
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

  Widget _buildYearDropdown(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String? value,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    final years = List.generate(2026 - 1960 + 1, (index) => (1960 + index).toString()).reversed.toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans.copyWith(
            fontSize: 10,
            color: isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.charcoal.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider, width: 0.8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text("Select Year", style: TextStyle(fontSize: 12, color: AppColors.charcoal.withValues(alpha: 0.3))),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.gold.withValues(alpha: 0.5)),
              dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              items: years.map((y) => DropdownMenuItem(
                value: y,
                child: Text(y, style: AppTextStyles.dmSans.copyWith(fontSize: 13, color: isDark ? Colors.white : AppColors.charcoal)),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
