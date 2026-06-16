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

    final bgSurface = isDark ? const Color(0xFF1C1C1C) : AppTokens.lightBgSurface;
    final bgPage = isDark ? const Color(0xFF0A0A0A) : AppTokens.lightBgPage;
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bgSurface,
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
                    : isDark ? Colors.white : Colors.black.withValues(alpha: 0.1),
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
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Select Categories",
                        style: AppTextStyles.headingMd.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppTokens.lightTextPrimary,
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
                      color: borderLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? Colors.white : AppTokens.lightTextPrimary,
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
                  AppTokens.lightBorderLight.withValues(alpha: 0),
                  AppTokens.lightBorderLight.withValues(alpha: 0.8),
                  AppTokens.lightBorderLight.withValues(alpha: 0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),

          // Cascading Filters (Main Category -> Subcategory -> File)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. MAIN CATEGORY
                  Text(
                    "Main Category",
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white.withValues(alpha: 0.6) : AppTokens.lightTextSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDropdown<String?>(
                    context: context,
                    isDark: isDark,
                    value: chatState.selectedMainCategoryId,
                    hint: "Select Category",
                    items: [
                      const DropdownMenuItem(value: null, child: Text("All Categories")),
                      ...chatState.categories.where((c) => c.parentId == null).map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      ref.read(chatProvider.notifier).selectMainCategory(val);
                    },
                  ),

                  // 2. SUBCATEGORY (Only show if Main Category has subcategories)
                  if (chatState.selectedMainCategoryId != null &&
                      chatState.categories.any((c) => c.parentId == chatState.selectedMainCategoryId)) ...[
                    const SizedBox(height: 16),
                    Text(
                      "Subcategory",
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white.withValues(alpha: 0.6) : AppTokens.lightTextSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown<String?>(
                      context: context,
                      isDark: isDark,
                      value: chatState.selectedSubCategoryId,
                      hint: "Select Subcategory",
                      items: [
                        const DropdownMenuItem(value: null, child: Text("All Subcategories")),
                        ...chatState.categories.where((c) => c.parentId == chatState.selectedMainCategoryId).map((cat) {
                          return DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        ref.read(chatProvider.notifier).selectSubCategory(val);
                      },
                    ),
                  ],

                  // Divider for specific document vs year filtering
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: borderLight)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "FILTER BY (Optional)",
                            style: AppTextStyles.bodyMd.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: borderLight)),
                      ],
                    ),
                  ),

                  // 3. FILE SELECTION
                  Opacity(
                    opacity: (chatState.yearFrom != null || chatState.yearTo != null) ? 0.4 : 1.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Specific File",
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white.withValues(alpha: 0.6) : AppTokens.lightTextSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDropdown<String?>(
                          context: context,
                          isDark: isDark,
                          value: chatState.selectedDocumentId,
                          hint: chatState.selectedMainCategoryId == null 
                            ? "Select a category first" 
                            : "Select File",
                          items: [
                            const DropdownMenuItem(value: null, child: Text("Any File")),
                            ...chatState.categoryDocuments.map((doc) {
                              return DropdownMenuItem(
                                value: doc['id'].toString(),
                                child: Text(doc['file_name']?.toString() ?? 'Unnamed File'),
                              );
                            }),
                          ],
                          onChanged: (chatState.yearFrom == null && chatState.yearTo == null && chatState.selectedMainCategoryId != null)
                              ? (val) => ref.read(chatProvider.notifier).selectDocument(val)
                              : null,
                        ),
                      ],
                    ),
                  ),

                  // OR divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: borderLight)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "OR",
                            style: AppTextStyles.bodyMd.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: borderLight)),
                      ],
                    ),
                  ),

                  // 4. YEAR FILTER
                  Opacity(
                    opacity: chatState.selectedDocumentId != null ? 0.4 : 1.0,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildYearDropdown(
                            context,
                            ref,
                            label: "From Year",
                            value: chatState.yearFrom,
                            onChanged: (val) {
                              if (chatState.selectedDocumentId != null) return;
                              ref
                                  .read(chatProvider.notifier)
                                  .updateYearRange(val, chatState.yearTo);
                            },
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
                            onChanged: (val) {
                              if (chatState.selectedDocumentId != null) return;
                              ref
                                  .read(chatProvider.notifier)
                                  .updateYearRange(chatState.yearFrom, val);
                            },
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Clear Filters Button
                  if (chatState.selectedMainCategoryId != null || chatState.yearFrom != null || chatState.yearTo != null)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(chatProvider.notifier).selectMainCategory(null);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Clear All Filters",
                                style: AppTextStyles.bodyMd.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black.withValues(
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
                  
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required bool isDark,
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required Function(T?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight,
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.2 : 0.02,
            ),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: AppTextStyles.bodyMd.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppTokens.darkTextSecondary
                  : AppTokens.lightTextSecondary,
              letterSpacing: 0.2,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: isDark
                ? AppTokens.darkTextSecondary
                : AppTokens.lightTextSecondary,
          ),
          style: AppTextStyles.bodyMd.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white
                : AppTokens.lightTextPrimary,
            letterSpacing: 0.2,
          ),
          dropdownColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items,
          onChanged: onChanged,
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
    final currentYear = DateTime.now().year;
    final maxYear = currentYear > 2026 ? currentYear : 2026;
    final years = List.generate(
      maxYear - 1960 + 1,
      (index) => (1960 + index).toString(),
    ).reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : isDark ? Colors.white : Colors.black.withValues(alpha: 0.6),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight,
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.2 : 0.02,
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
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTokens.darkTextSecondary
                      : AppTokens.lightTextSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: isDark
                    ? AppTokens.darkTextSecondary
                    : AppTokens.lightTextSecondary,
              ),
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white
                    : AppTokens.lightTextPrimary,
                letterSpacing: 0.2,
              ),
              dropdownColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              items: years
                  .map(
                    (y) => DropdownMenuItem(
                      value: y,
                      child: Text(
                        y,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.95)
                              : isDark ? Colors.white : Colors.black,
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

