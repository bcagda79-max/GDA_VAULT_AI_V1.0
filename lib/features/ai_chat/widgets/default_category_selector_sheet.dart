import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_state.dart';
import '../providers/chat_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class DefaultCategorySelectorSheet extends ConsumerStatefulWidget {
  const DefaultCategorySelectorSheet({super.key});

  @override
  ConsumerState<DefaultCategorySelectorSheet> createState() =>
      _DefaultCategorySelectorSheetState();
}

class _DefaultCategorySelectorSheetState
    extends ConsumerState<DefaultCategorySelectorSheet> {
  late Set<String> _selectedIds;
  late Set<String> _expandedParentIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = ref.read(chatProvider).defaultCategoryIds.toSet();
    _expandedParentIds = <String>{};
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return "${(count / 1000).toStringAsFixed(1)}k";
    }
    return count.toString();
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        return;
      }

      if (_selectedIds.length >= 2) return;
      _selectedIds.add(id);
    });
  }

  void _toggleParentExpansion(String parentId) {
    setState(() {
      if (_expandedParentIds.contains(parentId)) {
        _expandedParentIds.remove(parentId);
      } else {
        _expandedParentIds.add(parentId);
      }
    });
  }

  Future<void> _save() async {
    await ref
        .read(chatProvider.notifier)
        .updateDefaultCategoryIds(_selectedIds.toList());
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topCategories = chatState.categories
        .where((cat) => cat.parentId == null)
        .toList();
    final childrenByParent = <String, List<ChatCategory>>{};
    for (final cat in chatState.categories.where(
      (cat) => cat.parentId != null,
    )) {
      childrenByParent
          .putIfAbsent(cat.parentId!, () => <ChatCategory>[])
          .add(cat);
    }

    if (_selectedIds.isNotEmpty) {
      for (final selectedId in _selectedIds) {
        final selectedCat = chatState.categories
            .where((cat) => cat.id == selectedId)
            .toList();
        if (selectedCat.isNotEmpty && selectedCat.first.parentId != null) {
          _expandedParentIds.add(selectedCat.first.parentId!);
        }
      }
    }

    final selectedNames = topCategories.expand((cat) {
      final children = childrenByParent[cat.id] ?? const <ChatCategory>[];
      return [
        if (_selectedIds.contains(cat.id)) cat.name,
        ...children
            .where((child) => _selectedIds.contains(child.id))
            .map((child) => child.name),
      ];
    }).toList();

    final bgSurface = isDark ? const Color(0xFF1C1C1C) : AppTokens.lightBgSurface;
    final bgPage = isDark ? const Color(0xFF0A0A0A) : AppTokens.lightBgPage;
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;

    return Container(
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Standardized, Professional AppBar with proper SafeArea handling
          Container(
            decoration: BoxDecoration(
              color: bgPage,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: borderLight,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark ? Colors.white : AppTokens.lightTextPrimary,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Default Chat Categories",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTokens.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer for symmetry
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Status/Hint Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgPage,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedNames.isEmpty
                          ? "Select up to 2 default categories for new chats."
                          : "New chats will open with: ${selectedNames.join(', ')}",
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppTokens.darkTextSecondary
                            : AppTokens.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: topCategories.length,
              itemBuilder: (context, index) {
                final parent = topCategories[index];
                final isParentSelected = _selectedIds.contains(parent.id);
                final children =
                    childrenByParent[parent.id] ?? const <ChatCategory>[];
                final hasChildren = children.isNotEmpty;
                final isExpanded = _expandedParentIds.contains(parent.id);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Parent Category Item
                    _buildCategoryItem(
                      category: parent,
                      isSelected: isParentSelected,
                      isDark: isDark,
                      onTap: () {
                        _toggleCategory(parent.id);
                        if (hasChildren) {
                          _toggleParentExpansion(parent.id);
                        }
                      },
                      trailing: hasChildren
                          ? Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: isDark ? Colors.white38 : Colors.black26,
                            )
                          : null,
                    ),

                    // Sub-categories (Conditional)
                    if (hasChildren && isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Column(
                          children: children.map((child) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                left: 24,
                                bottom: 8,
                              ),
                              child: _buildCategoryItem(
                                category: child,
                                isSelected: _selectedIds.contains(child.id),
                                isDark: isDark,
                                isSubCategory: true,
                                onTap: () => _toggleCategory(child.id),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),

          // Footer Actions
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white60
                            : AppTokens.lightBrandPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedIds.isEmpty ? null : _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AppTokens.lightBrandPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: AppTokens.lightBrandPrimary.withOpacity(
                        0.4,
                      ),
                    ),
                    child: Text(
                      "Save Defaults",
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required ChatCategory category,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    bool isSubCategory = false,
    Widget? trailing,
  }) {
    final bgSurface = isDark ? const Color(0xFF1C1C1C) : AppTokens.lightBgSurface;
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withValues(alpha: isDark ? 0.15 : 0.08)
              : bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? category.color.withValues(alpha: 0.5)
                : borderLight,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: isSubCategory ? 32 : 40,
              height: isSubCategory ? 32 : 40,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSubCategory ? 8 : 10),
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: isSubCategory ? 16 : 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: isSubCategory ? 13 : 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isDark ? Colors.white : AppTokens.lightTextPrimary,
                    ),
                  ),
                  if (!isSubCategory)
                    Text(
                      "${_formatCount(category.docCount)} documents",
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 10,
                        color: isDark
                            ? Colors.white38
                            : AppTokens.lightBrandPrimary.withOpacity(0.4),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? category.color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? category.color : AppTokens.lightBorderLight,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

