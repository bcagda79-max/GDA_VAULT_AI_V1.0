import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'providers/chat_provider.dart';
import 'package:gda_vault_ai/features/ai_chat/models/chat_state.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/category_selector_sheet.dart';
import 'widgets/ai_chat_drawer.dart';
import 'package:gda_vault_ai/core/utils/responsive_app_bar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'widgets/suggested_questions.dart';

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
    _focusNode.addListener(_onFocusChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialDocumentId != null) {
        ref.read(chatProvider.notifier).sendMessage(
              "Tell me about this document.",
            );
      }
    });
  }

  void _onFocusChanged() {
    setState(() {
      _inputFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(text);
      _inputController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPage = isDark ? const Color(0xFF0A0A0A) : AppTokens.lightBgPage;

    return Scaffold(
      backgroundColor: bgPage,
      drawer: const AiChatDrawer(),
      body: Column(
        children: [
          _buildAppBar(isDark),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    children: [
                      if (chatState.messages.isNotEmpty)
                        _buildFilterBar(chatState, isDark),
                      Expanded(
                        child: chatState.messages.isEmpty
                            ? _buildCleanEmptyState(isDark)
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                itemCount: chatState.messages.length,
                                itemBuilder: (ctx, i) => ChatMessageBubble(
                                  message: chatState.messages[i],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildInputArea(chatState, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isDesktop = ResponsiveAppBar.isDesktop(context);
    final bgSurface = isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
    final textPrimary = isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary;

    return PreferredSize(
      preferredSize: Size.fromHeight(
        isDesktop ? ResponsiveAppBar.desktopHeight : (isLandscape ? 48.0 : 56.0),
      ),
      child: AppBar(
        backgroundColor: bgSurface,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderLight, width: 1)),
          ),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: Padding(
                padding: isDesktop
                    ? ResponsiveAppBar.desktopPadding
                    : const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: Icon(
                          Icons.menu_outlined,
                          color: textPrimary,
                          size: 24,
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "AI CHAT",
                            style: AppTextStyles.labelSm.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "GDA Vault Intelligence",
                            style: AppTextStyles.labelSm.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: isDark ? const Color(0xFF8899B0) : AppTokens.lightTextSecondary,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.home_outlined,
                        color: textPrimary,
                        size: 24,
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

  Widget _buildFilterBar(ChatState state, bool isDark) {
    final bgSurface = isDark ? const Color(0xFF141414) : const Color(0xFFF9F9F9);
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final activeBg = isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bgSurface,
        border: Border(bottom: BorderSide(color: borderLight, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, size: 16, color: textSecondary),
          const SizedBox(width: 8),
          Text(
            "Filter:",
            style: AppTextStyles.bodyMd.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (state.categoriesSelected)
                    _buildFilterChip("Categories", activeBg, textSecondary),
                  if (!state.categoriesSelected)
                    Text(
                      "None",
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const CategorySelectorSheet(),
              );
            },
            child: Text(
              "Change",
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, Color bg, Color text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMd.copyWith(
          fontSize: 11,
          color: text,
        ),
      ),
    );
  }

  Widget _buildCleanEmptyState(bool isDark) {
    final textPrimary = isDark ? Colors.white : AppTokens.lightTextPrimary;
    final textSecondary = isDark ? const Color(0xFF888888) : AppTokens.lightTextSecondary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF141414) : Colors.white,
                boxShadow: isDark ? AppTokens.darkShadowSm : AppTokens.lightShadowSm,
                border: Border.all(
                  color: isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    'assets/images/gda_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              "How can I help you today?",
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMd.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 12),
            Text(
              "Ask me anything about GDA projects, documents, or general queries. I'm here to assist you.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 40),
            const SuggestedQuestions().animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatState state, bool isDark) {
    final canSend = state.canSendMessage;
    final bgPage = isDark ? const Color(0xFF0A0A0A) : AppTokens.lightBgPage;
    final bgPill = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF3F4F6);
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: bgPage,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bgPage.withValues(alpha: 0.0),
            bgPage.withValues(alpha: 0.8),
            bgPage,
          ],
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.only(left: 20, right: 8, top: 4, bottom: 4),
          decoration: BoxDecoration(
            color: bgPill,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: _inputFocused ? (isDark ? Colors.white24 : Colors.black12) : borderLight,
              width: 1,
            ),
            boxShadow: [
              if (_inputFocused)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TextField(
                    controller: _inputController,
                    focusNode: _focusNode,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    keyboardType: TextInputType.multiline,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 14,
                      color: isDark ? Colors.white : AppTokens.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: state.categoriesSelected
                          ? "Message GDA Vault AI..."
                          : "Select categories to message...",
                      hintStyle: AppTextStyles.bodyMd.copyWith(
                        fontSize: 14,
                        color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: canSend 
                      ? (isDark ? Colors.white : AppTokens.lightTextPrimary)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_upward_rounded,
                    size: 20,
                    color: canSend 
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? const Color(0xFF555555) : AppTokens.lightBorderMedium),
                  ),
                  onPressed: canSend ? _sendMessage : null,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
