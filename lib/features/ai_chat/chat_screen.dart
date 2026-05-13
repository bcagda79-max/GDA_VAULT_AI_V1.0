import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'providers/chat_provider.dart';
import 'package:gda_vault_ai/features/ai_chat/models/chat_state.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/category_selector_sheet.dart';
import 'widgets/ai_chat_drawer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? initialDocumentId;
  final String? initialCategoryId;
  final String? initialSubCategoryId;
  final String? initialYear;

  const ChatScreen({
    super.key,
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
      final hasInitialParams =
          widget.initialCategoryId != null ||
          widget.initialSubCategoryId != null ||
          widget.initialYear != null ||
          widget.initialDocumentId != null;

      if (hasInitialParams) {
        // Start a new chat context only if explicitly triggered with parameters
        ref.read(chatProvider.notifier).startNewChat();

        if (widget.initialCategoryId != null ||
            widget.initialSubCategoryId != null) {
          // Automatically select the specific category/sub-category
          ref
              .read(chatProvider.notifier)
              .selectSpecificCategory(
                widget.initialCategoryId,
                widget.initialSubCategoryId,
              );
        }

        // If year is provided, pre-fill it for the user
        if (widget.initialYear != null) {
          ref
              .read(chatProvider.notifier)
              .updateYearRange(widget.initialYear, widget.initialYear);
        }
      }
      // If no params, simply retain the current chat session and its selections!
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

    // Auto-scroll when new messages arrive
    ref.listen(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
      // Listen for filter sheet signal
      if (next.showFilterSheet && !(previous?.showFilterSheet ?? false)) {
        _openCategorySheet();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
      appBar: _buildAppBar(isDark),
      drawer: const AiChatDrawer(),
      body: Stack(
        children: [
          _buildBackdrop(isDark),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child:
                      !chatState.categoriesSelected &&
                          chatState.messages.isEmpty
                      ? _buildCategoryRequiredBanner(isDark)
                      : Column(
                          children: [
                            if (chatState.categoriesSelected &&
                                chatState.yearFrom == null &&
                                chatState.yearTo == null)
                              _buildYearHintCard(isDark),
                            Expanded(
                              child: chatState.messages.isEmpty
                                  ? _buildEmptyState(isDark)
                                  : ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      itemCount: chatState.messages.length,
                                      itemBuilder: (ctx, i) =>
                                          ChatMessageBubble(
                                            message: chatState.messages[i],
                                          ),
                                    ),
                            ),
                          ],
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

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(76.0),
      child: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0D1221), const Color(0xFF070C1A)]
                  : [AppColors.navyDark, AppColors.navyMid],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.menu_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "GDA AI CHAT",
                            style: AppTextStyles.playfairDisplay.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () => context.go('/dashboard'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
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
                ? [const Color(0xFF0A0F1E), const Color(0xFF070C1A)]
                : [const Color(0xFFFDFBF7), const Color(0xFFF5F2EB)],
          ),
        ),
        child: Stack(
          children: [
            // Subtle tech pattern overlay
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.03 : 0.02,
                child: CustomPaint(painter: _GridPainter(isDark: isDark)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearHintCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Select year for better response",
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.charcoal.withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: _openCategorySheet,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              "Select",
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildCategoryRequiredBanner(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child:
          Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.divider,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.08,
                      ),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child:
                            Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 36,
                                  color: AppColors.gold,
                                )
                                .animate(
                                  onPlay: (controller) => controller.repeat(),
                                )
                                .rotate(
                                  duration: 3.seconds,
                                  curve: Curves.linear,
                                ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Select categories to start chat",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.playfairDisplay.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.darkText : AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Only two categories can be selected at a time. Select year as well for better reasoning and more precise answers.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 14,
                        height: 1.6,
                        color: (isDark ? Colors.white : AppColors.charcoal)
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: _openCategorySheet,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.navyDark, AppColors.navyMid],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navyDark.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.filter_alt_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Choose Categories",
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.95, 0.95),
                curve: Curves.easeOutCubic,
              ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 30,
                  color: AppColors.gold,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(
                begin: -5,
                end: 5,
                duration: 2.seconds,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 20),
          Text(
            "Ready to Search",
            style: AppTextStyles.playfairDisplay.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.darkText : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ask anything about the selected\ndocument categories",
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 14,
              color: (isDark ? Colors.white : AppColors.charcoal).withValues(
                alpha: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatState state, bool isDark) {
    final canSend = state.canSendMessage;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.paper,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _inputFocused
                ? AppColors.gold.withValues(alpha: 0.5)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.divider.withValues(alpha: 0.8)),
            width: 1,
          ),
          boxShadow: [
            if (_inputFocused)
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _openCategorySheet,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.language_rounded,
                  size: 20,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.navyDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                keyboardType: TextInputType.multiline,
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 15,
                  color: isDark ? Colors.white : AppColors.charcoal,
                ),
                decoration: InputDecoration(
                  hintText: state.categoriesSelected
                      ? "Message"
                      : "Select categories...",
                  hintStyle: AppTextStyles.dmSans.copyWith(
                    fontSize: 15,
                    color: (isDark ? Colors.white : AppColors.charcoal)
                        .withValues(alpha: 0.3),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                ),
                onChanged: (val) =>
                    ref.read(chatProvider.notifier).updateInput(val),
                onSubmitted: (val) => _sendMessage(val),
                enabled: state.categoriesSelected,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: canSend ? 40 : 0,
              height: canSend ? 40 : 0,
              child: AnimatedOpacity(
                opacity: canSend ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: canSend ? () => _sendMessage() : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : AppColors.navyDark,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.white : AppColors.navyDark)
                              .withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 22,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white : Colors.black
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
