import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/chat_state.dart';
import '../providers/chat_provider.dart';
import 'category_selector_sheet.dart';

class AiChatDrawer extends ConsumerWidget {
  const AiChatDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final isLandscape = mq.orientation == Orientation.landscape;
    final drawerWidth = screenWidth >= 900
        ? screenWidth * 0.5
        : (isLandscape ? screenWidth * 0.3 : screenWidth * 0.7);

    final bgSurface = isDark ? const Color(0xFF141414) : AppTokens.lightBgSurface;

    return Drawer(
      backgroundColor: bgSurface,
      width: drawerWidth,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, ref, isDark),
            Expanded(
              child: _buildConversationSection(context, chatState, ref, isDark),
            ),
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isDark) {
    final textPrimary = isDark ? const Color(0xFFEBEBEB) : AppTokens.lightTextPrimary;
    final textSecondary = isDark ? const Color(0xFF8A8A8A) : AppTokens.lightTextSecondary;
    final searchBg = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F2F5);
    final searchBorder = isDark ? const Color(0xFF272727) : const Color(0xFFE4E7EC);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chats',
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: textSecondary),
                onPressed: () {
                  ref.read(chatProvider.notifier).startNewChat();
                  Navigator.pop(context);
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    // Existing search callback or open search
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: searchBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: searchBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 16,
                          color: isDark ? const Color(0xFF555555) : textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Search',
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF555555) : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  // Close drawer and open filter sheet
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => const CategorySelectorSheet(),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: searchBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: searchBorder),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF555555) : textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversationSection(
    BuildContext context,
    ChatState state,
    WidgetRef ref,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'CHATS',
            style: AppTextStyles.bodyMd.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF555555) : AppTokens.lightTextTertiary,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Expanded(
          child: state.recentSessions.isEmpty
              ? _buildEmptyHistory(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: state.recentSessions.length,
                  itemBuilder: (context, index) {
                    final session = state.recentSessions[index];
                    final isSelected = state.sessionId == session['id'];
                    return _buildHistoryItem(
                      context,
                      session,
                      isSelected,
                      ref,
                      isDark,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistory(bool isDark) {
    return Center(
      child: Text(
        'No recent chats',
        style: AppTextStyles.bodyMd.copyWith(
          fontSize: 13,
          color: isDark ? const Color(0xFF8A8A8A) : AppTokens.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    Map<String, dynamic> session,
    bool isSelected,
    WidgetRef ref,
    bool isDark,
  ) {
    final hoverBg = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF5F5F5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () {
          ref.read(chatProvider.notifier).loadSession(session['id']);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(6),
        hoverColor: hoverBg,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  session['title'] ?? 'New Chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected 
                        ? (isDark ? const Color(0xFFEBEBEB) : AppTokens.lightTextPrimary)
                        : (isDark ? const Color(0xFF8A8A8A) : AppTokens.lightTextSecondary),
                  ),
                ),
              ),
              if (isSelected)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF555555) : AppTokens.lightTextSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    if (val == 'delete') {
                      _showDeleteDialog(
                        context,
                        ref,
                        session['id'],
                        session['title']?.toString() ?? 'New Chat',
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    final borderTop = isDark ? const Color(0xFF272727) : const Color(0xFFE4E7EC);
    final textPrimary = isDark ? const Color(0xFFEBEBEB) : AppTokens.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderTop),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F2F5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF272727) : const Color(0xFFE4E7EC),
              ),
            ),
            child: Center(
              child: Text(
                "GA",
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'GDA User',
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(dialogContext).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            'Delete chat?',
            style: AppTextStyles.headingMd.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: Text(
            'This will permanently delete "$title" from local storage.',
            style: AppTextStyles.bodyMd.copyWith(fontSize: 14),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref.read(chatProvider.notifier).deleteSession(sessionId);
              },
            ),
          ],
        );
      },
    );
  }
}
