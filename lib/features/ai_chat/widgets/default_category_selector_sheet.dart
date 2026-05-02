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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 14, bottom: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.charcoal.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Default Chat Categories",
                          style: AppTextStyles.playfairDisplay.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.charcoal,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Choose 1 or 2 categories for new chats",
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 12,
                            color: AppColors.charcoal.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navyLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${_selectedIds.length}/2",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyLight,
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
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : AppColors.navyLight.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.navyLight.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.navyLight.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 15,
                        color: AppColors.navyLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedNames.isEmpty
                            ? "No defaults selected yet."
                            : "New chats will open with: ${selectedNames.join(', ')}",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.75)
                              : AppColors.charcoal.withValues(alpha: 0.75),
                          height: 1.3,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: topCategories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final cat = topCategories[index];
                  final isSelected = _selectedIds.contains(cat.id);
                  final children =
                      childrenByParent[cat.id] ?? const <ChatCategory>[];
                  final hasChildren = children.isNotEmpty;
                  final isExpanded =
                      _expandedParentIds.contains(cat.id) ||
                      (hasChildren && isSelected);
                  return InkWell(
                    onTap: () {
                      _toggleCategory(cat.id);
                      if (hasChildren) {
                        _toggleParentExpansion(cat.id);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withValues(alpha: isDark ? 0.12 : 0.08)
                            : (isDark ? AppColors.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? cat.color.withValues(alpha: isDark ? 0.4 : 0.28)
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppColors.divider),
                          width: isSelected ? 1.2 : 0.9,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: cat.color.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cat.color.withValues(
                                alpha: isSelected ? 0.18 : 0.08,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              cat.icon,
                              color: cat.color.withValues(
                                alpha: isSelected ? 1 : 0.7,
                              ),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: AppTextStyles.dmSans.copyWith(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.charcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${_formatCount(cat.docCount)} documents",
                                  style: AppTextStyles.dmSans.copyWith(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : AppColors.charcoal.withValues(
                                            alpha: 0.45,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? cat.color
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? cat.color
                                    : AppColors.divider,
                                width: isSelected ? 2 : 1.4,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          if (hasChildren) ...[
                            const SizedBox(width: 6),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 18,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.45)
                                  : AppColors.charcoal.withValues(alpha: 0.45),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selectedIds.any(
              (id) => childrenByParent.values
                  .expand((list) => list)
                  .any((child) => child.id == id),
            ))
              const SizedBox(height: 6),
            if (topCategories.any(
              (cat) =>
                  _expandedParentIds.contains(cat.id) ||
                  (_selectedIds.contains(cat.id) &&
                      (childrenByParent[cat.id]?.isNotEmpty ?? false)),
            ))
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Column(
                  children: topCategories
                      .where((cat) {
                        final children =
                            childrenByParent[cat.id] ?? const <ChatCategory>[];
                        return children.isNotEmpty &&
                            (_expandedParentIds.contains(cat.id) ||
                                _selectedIds.contains(cat.id));
                      })
                      .expand((parent) {
                        final children =
                            childrenByParent[parent.id] ??
                            const <ChatCategory>[];
                        return children.map((child) {
                          final isSelected = _selectedIds.contains(child.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => _toggleCategory(child.id),
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? child.color.withValues(
                                          alpha: isDark ? 0.12 : 0.08,
                                        )
                                      : (isDark
                                            ? AppColors.darkCard.withValues(
                                                alpha: 0.8,
                                              )
                                            : AppColors.paper.withValues(
                                                alpha: 0.7,
                                              )),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? child.color.withValues(
                                            alpha: isDark ? 0.4 : 0.28,
                                          )
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.08,
                                                )
                                              : AppColors.divider),
                                    width: isSelected ? 1.2 : 0.9,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 20),
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: child.color.withValues(
                                          alpha: isSelected ? 0.18 : 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        child.icon,
                                        color: child.color.withValues(
                                          alpha: isSelected ? 1 : 0.7,
                                        ),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            child.name,
                                            style: AppTextStyles.dmSans
                                                .copyWith(
                                                  fontSize: 13,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.white
                                                      : AppColors.charcoal,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${_formatCount(child.docCount)} documents",
                                            style: AppTextStyles.dmSans
                                                .copyWith(
                                                  fontSize: 10,
                                                  color: isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.4,
                                                        )
                                                      : AppColors.charcoal
                                                            .withValues(
                                                              alpha: 0.45,
                                                            ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? child.color
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? child.color
                                              : AppColors.divider,
                                          width: isSelected ? 2 : 1.4,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 13,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        });
                      })
                      .toList(),
                ),
              ),
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
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(
                          color: AppColors.divider.withValues(alpha: 0.8),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.charcoal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedIds.isEmpty || _selectedIds.length > 2
                          ? null
                          : _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.navyDark,
                        disabledBackgroundColor: AppColors.navyDark.withValues(
                          alpha: 0.35,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Save Defaults",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
