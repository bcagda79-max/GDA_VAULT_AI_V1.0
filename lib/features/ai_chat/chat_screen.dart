import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/chat_provider.dart';
import 'package:gda_vault_ai/features/ai_chat/models/chat_state.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/category_selector_sheet.dart';
import 'widgets/ai_chat_drawer.dart';
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
      if (widget.initialCategoryId != null ||
          widget.initialSubCategoryId != null) {
        // Automatically select the specific category/sub-category
        ref
            .read(chatProvider.notifier)
            .selectSpecificCategory(
              widget.initialCategoryId,
              widget.initialSubCategoryId,
            );

        // If year is provided, pre-fill it for the user
        if (widget.initialYear != null) {
          ref
              .read(chatProvider.notifier)
              .updateYearRange(widget.initialYear, widget.initialYear);
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
      body: Stack(
        children: [
          _buildBackdrop(isDark),
          SafeArea(
            top: !widget.isPushed,
            child: Column(
              children: [
                if (!widget.isPushed) _buildTabHeader(selectedCount, isDark),
                Expanded(
                  child:
                      !chatState.categoriesSelected &&
                          chatState.messages.isEmpty
                      ? _buildCategoryRequiredBanner(isDark)
                      : (chatState.categoriesSelected &&
                            chatState.yearFrom == null &&
                            chatState.yearTo == null &&
                            chatState.messages.isEmpty)
                      ? _buildYearRequiredBanner(isDark)
                      : chatState.messages.isEmpty &&
                            chatState.categoriesSelected
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: chatState.messages.length,
                          itemBuilder: (ctx, i) =>
                              ChatMessageBubble(message: chatState.messages[i]),
                        ),
                ),
                _buildInputArea(chatState, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearRequiredBanner(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.divider,
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withValues(alpha: isDark ? 0.12 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.navyDark.withValues(alpha: 0.28)
                    : AppColors.navyDark.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.navyLight.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 34,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.88)
                      : AppColors.navyDark.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Select Year",
              textAlign: TextAlign.center,
              style: AppTextStyles.playfairDisplay.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please select at least one year to start the chat.\nThis helps produce more accurate answers.",
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.68)
                    : AppColors.charcoal.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _openCategorySheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.navyDark, AppColors.navyLight],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyDark.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Select Year",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
    );
  }

  Widget _buildBackdrop(bool isDark) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF070C1A), AppColors.darkBg]
                : [const Color(0xFFF9F5EC), AppColors.paper],
          ),
        ),
        child: Stack(children: [
          ],
        ),
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
                ? [
                    AppColors.navyDark,
                    AppColors.navyDark.withValues(alpha: 0.8),
                  ]
                : [AppColors.navyDark, AppColors.navyLight],
          ),
        ),
      ),
      elevation: 0,
      toolbarHeight: 62,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Colors.white,
        ),
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
        GestureDetector(
          onTap: _openCategorySheet,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selectedCount > 0
                  ? AppColors.navyLight.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: selectedCount > 0
                  ? Border.all(
                      color: AppColors.navyLight.withValues(alpha: 0.4),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt_rounded,
                  size: 14,
                  color: selectedCount > 0
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  selectedCount > 0 ? "$selectedCount" : "Filter",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 10,
                    fontWeight: selectedCount > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selectedCount > 0
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDark, AppColors.navyLight],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "AI Chat",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.playfairDisplay.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Ask anything about GDA documents",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _openCategorySheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: selectedCount > 0
                    ? AppColors.navyLight.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedCount > 0
                      ? AppColors.navyLight.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_alt_rounded,
                    size: 13,
                    color: selectedCount > 0
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.82),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    selectedCount > 0 ? "$selectedCount selected" : "Filters",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selectedCount > 0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRequiredBanner(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.divider,
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withValues(alpha: isDark ? 0.12 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.navyDark.withValues(alpha: 0.28)
                    : AppColors.navyDark.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.navyLight.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 36,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.88)
                      : AppColors.navyDark.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Select categories to start chat",
              textAlign: TextAlign.center,
              style: AppTextStyles.playfairDisplay.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Only two categories can be selected at a time. Select year as well for better reasoning and more precise answers.",
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.68)
                    : AppColors.charcoal.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _openCategorySheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.navyDark, AppColors.navyLight],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyDark.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.filter_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Click here to select categories",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
                color: AppColors.navyLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.navyLight.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 26,
                  color: AppColors.navyLight,
                ),
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
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppColors.charcoal.withValues(alpha: 0.45),
              ),
            ),
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
            color: AppColors.navyDark.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, -1),
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
          GestureDetector(
            onTap: _openCategorySheet,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: state.categoriesSelected
                    ? AppColors.navyLight.withValues(alpha: 0.18)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.charcoal.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: state.categoriesSelected
                      ? AppColors.navyLight.withValues(alpha: 0.45)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppColors.divider),
                  width: 1,
                ),
                boxShadow: state.categoriesSelected
                    ? [
                        BoxShadow(
                          color: AppColors.navyLight.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  state.categoriesSelected
                      ? Icons.filter_alt_rounded
                      : Icons.filter_alt_outlined,
                  size: 20,
                  color: state.categoriesSelected
                      ? AppColors.navyDark
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppColors.charcoal.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.paper,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _inputFocused
                      ? AppColors.navyLight.withValues(alpha: 0.45)
                      : AppColors.divider,
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
                  hintText: state.categoriesSelected
                      ? "Ask about GDA documents..."
                      : "Select categories first...",
                  hintStyle: AppTextStyles.dmSans.copyWith(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : AppColors.charcoal.withValues(alpha: 0.35),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (val) =>
                    ref.read(chatProvider.notifier).updateInput(val),
                onSubmitted: (val) => _sendMessage(val),
                enabled: state.categoriesSelected,
              ),
            ),
          ),
          if (canSend)
            GestureDetector(
              onTap: () => _sendMessage(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.navyLight,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyLight.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
