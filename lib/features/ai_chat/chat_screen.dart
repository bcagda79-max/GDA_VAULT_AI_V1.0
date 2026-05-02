import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/chat_provider.dart';
import 'package:gda_vault_ai/features/ai_chat/models/chat_state.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/category_selector_sheet.dart';
import 'widgets/ai_chat_drawer.dart';
import 'widgets/suggested_questions.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final bool isPushed;
  final String? initialDocumentId;
  final String? initialCategoryId;
  final String? initialSubCategoryId;
  final String? initialYear;

  const ChatScreen({
    super.key,
    this.isPushed = false,
    this.initialDocumentId,
    this.initialCategoryId,
    this.initialSubCategoryId,
    this.initialYear,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _inputFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _initializeFromContext();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId ||
        widget.initialSubCategoryId != oldWidget.initialSubCategoryId ||
        widget.initialYear != oldWidget.initialYear) {
      _initializeFromContext();
    }
  }

  void _initializeFromContext() {
    // Smart Initialization from PDF Viewer or Home FAB
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCategoryId != null || widget.initialSubCategoryId != null) {
        // Automatically select the specific category/sub-category
        ref.read(chatProvider.notifier).selectSpecificCategory(
          widget.initialCategoryId,
          widget.initialSubCategoryId,
        );
        
        // If year is provided, pre-fill it for the user
        if (widget.initialYear != null) {
          ref.read(chatProvider.notifier).updateYearRange(
            widget.initialYear,
            widget.initialYear,
          );
        }
      } else if (widget.isPushed) {
        // If just pushed without specific context, select all for convenience
        ref.read(chatProvider.notifier).selectAllCategories();
      }
    });
  }

  void _onFocusChange() {
    setState(() {
      _inputFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage([String? text]) {
    final msg = text ?? _inputController.text;
    final chatState = ref.read(chatProvider);
    if (msg.trim().isEmpty || !chatState.categoriesSelected) return;
    
    _inputController.clear();
    ref.read(chatProvider.notifier).sendMessage(msg);
    _focusNode.unfocus();
  }

  void _openCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CategorySelectorSheet(),
    );
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.darkSurface 
            : Colors.white,
        title: Text("Clear Chat?", style: AppTextStyles.playfairDisplay.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text("All chat history will be removed.",
          style: AppTextStyles.dmSans.copyWith(
            fontSize: 14,
            color: AppColors.charcoal.withValues(alpha: 0.55))),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: AppTextStyles.dmSans.copyWith(color: AppColors.charcoal.withValues(alpha: 0.5)))),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
              Navigator.pop(ctx);
            },
            child: Text("Clear", 
              style: AppTextStyles.dmSans.copyWith(color: AppColors.catPrivate, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCount = chatState.selectedCategories.length;

    // Auto-scroll when new messages arrive
    ref.listen(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
      appBar: widget.isPushed ? _buildAppBar(selectedCount, isDark) : null,
      drawer: const AiChatDrawer(),
      body: Column(
        children: [
          if (!widget.isPushed) _buildTabHeader(selectedCount, isDark),
          
          _buildFilterChipsBar(chatState, isDark),
          
          if (!chatState.categoriesSelected && chatState.messages.isEmpty)
            _buildCategoryRequiredBanner(isDark),
          
          // Messages List
          Expanded(
            child: chatState.messages.isEmpty && chatState.categoriesSelected
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: chatState.messages.length,
                    itemBuilder: (ctx, i) => ChatMessageBubble(message: chatState.messages[i]),
                  ),
          ),
          
          // Input Area
          _buildInputArea(chatState, isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int selectedCount, bool isDark) {
    return AppBar(
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
      toolbarHeight: 62,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            "GDA Vault AI",
            style: AppTextStyles.playfairDisplay.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            "Document Intelligence",
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
      actions: [
        if (ref.read(chatProvider).messages.isNotEmpty)
          IconButton(
            onPressed: _confirmClearChat,
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_sweep_rounded, size: 17, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: _openCategorySheet,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selectedCount > 0 ? AppColors.gold.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: selectedCount > 0 ? Border.all(color: AppColors.gold.withValues(alpha: 0.4)) : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 14,
                  color: selectedCount > 0 ? AppColors.gold : Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  selectedCount > 0 ? "$selectedCount" : "Filter",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 10,
                    fontWeight: selectedCount > 0 ? FontWeight.bold : FontWeight.normal,
                    color: selectedCount > 0 ? AppColors.gold : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTabHeader(int selectedCount, bool isDark) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navyDark, AppColors.navyDark.withValues(alpha: 0.9)],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.menu_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Chat",
                        style: AppTextStyles.playfairDisplay.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Ask anything about GDA documents",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  if (ref.read(chatProvider).messages.isNotEmpty)
                    GestureDetector(
                      onTap: _confirmClearChat,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.delete_sweep_rounded, size: 15, color: Colors.white.withValues(alpha: 0.6)),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _openCategorySheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selectedCount > 0 ? AppColors.gold.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: selectedCount > 0 ? Border.all(color: AppColors.gold.withValues(alpha: 0.3)) : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 13,
                            color: selectedCount > 0 ? AppColors.gold : Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            selectedCount > 0 ? "$selectedCount selected" : "Filters",
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 10,
                              fontWeight: selectedCount > 0 ? FontWeight.bold : FontWeight.normal,
                              color: selectedCount > 0 ? AppColors.gold : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

Widget _buildFilterChipsBar(ChatState state, bool isDark) {
  final categories = state.selectedCategories;
  final hasYearFilter = state.yearFrom != null || state.yearTo != null;
  
  String yearRangeText = "All Years";
  if (hasYearFilter) {
    if (state.yearFrom != null && state.yearTo != null) {
      yearRangeText = state.yearFrom == state.yearTo ? state.yearFrom! : "${state.yearFrom} — ${state.yearTo}";
    } else {
      yearRangeText = state.yearFrom ?? state.yearTo ?? "All Years";
    }
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : Colors.white,
      border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.8)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(
            icon: Icons.auto_awesome_motion_rounded,
            label: categories.isEmpty ? "All Archives" : categories.map((c) => c.shortName).join(", "),
            isActive: categories.isNotEmpty,
            onTap: _openCategorySheet,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: Icons.history_toggle_off_rounded,
            label: yearRangeText,
            isActive: hasYearFilter,
            onTap: _openCategorySheet,
            isDark: isDark,
          ),
          if (categories.isNotEmpty || hasYearFilter) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                ref.read(chatProvider.notifier).clearAllCategories();
                ref.read(chatProvider.notifier).updateYearRange(null, null);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  "Reset",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.catPrivate,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildFilterChip({
  required IconData icon,
  required String label,
  required bool isActive,
  required VoidCallback onTap,
  required bool isDark,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isActive 
          ? AppColors.navyDark 
          : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.navyDark.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive 
            ? AppColors.gold.withValues(alpha: 0.5) 
            : (isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.divider),
          width: 0.8,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isActive ? AppColors.gold : (isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.charcoal.withValues(alpha: 0.4)),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? Colors.white : (isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.charcoal.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 12,
            color: isActive ? Colors.white.withValues(alpha: 0.5) : (isDark ? Colors.white.withValues(alpha: 0.2) : AppColors.charcoal.withValues(alpha: 0.2)),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCategoryRequiredBanner(bool isDark) {
    final categories = ref.read(chatProvider).categories.where((c) => c.parentId == null).toList();
    
    return Container(
      color: isDark ? AppColors.darkBg : AppColors.paper,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Empty state illustration
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.navyDark.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 36,
                color: isDark ? Colors.white.withValues(alpha: 0.25) : AppColors.navyDark.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Select Categories to Start",
            style: AppTextStyles.playfairDisplay.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Choose up to 2 document categories you want\nto search and ask questions about.",
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 13,
              color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.charcoal.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          // Quick category selection chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: categories.map((cat) {
              return GestureDetector(
                onTap: () {
                  final chatState = ref.read(chatProvider);
                  if (!cat.isSelected && chatState.selectedCategories.length >= 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Maximum 2 categories allowed for focused AI context"),
                        backgroundColor: AppColors.navyDark,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    return;
                  }
                  ref.read(chatProvider.notifier).toggleCategory(cat.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cat.isSelected ? cat.color.withValues(alpha: 0.12) : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: cat.isSelected ? cat.color : AppColors.divider,
                      width: cat.isSelected ? 1.5 : 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 15, color: cat.isSelected ? cat.color : AppColors.charcoal.withValues(alpha: 0.4)),
                      const SizedBox(width: 7),
                      Text(
                        cat.name,
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 12,
                          color: cat.isSelected 
                              ? cat.color 
                              : (isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.charcoal.withValues(alpha: 0.6)),
                          fontWeight: cat.isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Info Badge instead of Select All
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.gold),
                const SizedBox(width: 6),
                Text(
                  "Multi-category search enabled (Max 2)",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome_rounded, size: 26, color: AppColors.gold),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Ready to Search",
              style: AppTextStyles.playfairDisplay.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Ask anything about the selected\ndocument categories",
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 12,
                color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.charcoal.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 32),
            const SuggestedQuestions(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatState state, bool isDark) {
    final canSend = state.canSendMessage;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Category selector button
          GestureDetector(
            onTap: _openCategorySheet,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: state.categoriesSelected 
                    ? AppColors.gold.withValues(alpha: 0.15) 
                    : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.charcoal.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: state.categoriesSelected 
                      ? AppColors.gold.withValues(alpha: 0.4) 
                      : (isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.divider),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  state.categoriesSelected ? Icons.tune_rounded : Icons.add_rounded,
                  size: 19,
                  color: state.categoriesSelected 
                      ? AppColors.gold 
                      : (isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.charcoal.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Text Input
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.paper,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _inputFocused ? AppColors.gold.withValues(alpha: 0.5) : AppColors.divider,
                  width: _inputFocused ? 1.5 : 0.8,
                ),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                keyboardType: TextInputType.multiline,
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 14,
                  color: isDark ? AppColors.darkText : AppColors.charcoal,
                ),
                decoration: InputDecoration(
                  hintText: state.categoriesSelected ? "Ask about GDA documents..." : "Select categories first...",
                  hintStyle: AppTextStyles.dmSans.copyWith(
                    fontSize: 13,
                    color: isDark ? Colors.white.withValues(alpha: 0.3) : AppColors.charcoal.withValues(alpha: 0.35),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) => ref.read(chatProvider.notifier).updateInput(val),
                onSubmitted: (val) => _sendMessage(val),
                enabled: state.categoriesSelected,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send Button
          GestureDetector(
            onTap: canSend ? () => _sendMessage() : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: canSend
                    ? const LinearGradient(colors: [AppColors.navyDark, Color(0xFF1A3A6B)])
                    : null,
                color: canSend 
                    ? null 
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.charcoal.withValues(alpha: 0.08)),
                border: canSend ? null : Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                  width: 1,
                ),
                boxShadow: canSend
                    ? [
                        BoxShadow(
                          color: AppColors.navyDark.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: canSend 
                      ? Colors.white 
                      : (isDark ? Colors.white.withValues(alpha: 0.2) : AppColors.charcoal.withValues(alpha: 0.25)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
