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
    _focusNode.addListener(_onFocus
                          Icons.menu_outlined,
                          color: isDark ? Colors.white : AppTokens.lightTextPrimary,
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
                            style: AppTextStyles.headingMd.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTokens.lightTextPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "GDA Vault Intelligence",
                            style: AppTextStyles.bodyMd.copyWith(
                              fontSize: 10,
                              color: isDark ? const Color(0xFF8899B0) : AppTokens.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.home_outlined,
                        color: isDark ? Colors.white : AppTokens.lightTextPrimary,
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
    final bgSurface = isDark ? const Color(0xFF1C1C1C) : AppTokens.lightBgSurface;
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;

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
              scrollDirection: Axis.horizonta
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _inputFocused ? AppTokens.lightBrandPrimary : borderLight,
            width: 1,
          ),
          boxShadow: [
            if (_inputFocused)
              BoxShadow(
                color: AppTokens.lightBrandPrimary.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
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