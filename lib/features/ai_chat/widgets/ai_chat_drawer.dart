import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/chat_state.dart';
import '../providers/chat_provider.dart';

class AiChatDrawer extends ConsumerWidget {
  const AiChatDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          _buildTopBar(context, ref, isDark),
          _buildMainActions(context, ref, isDark),
          _buildConversationSection(context, chatState, ref, isDark),
          _buildFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 10,
        16,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.05,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color:
                        (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightText)
                            .withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search',
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 14,
                        color:
                            (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightText)
                                .withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              ref.read(chatProvider.notifier).startNewChat();
              Navigator.pop(context);
            },
            child: Icon(
              Icons.edit_note_rounded,
              size: 26,
              color: isDark ? AppColors.darkIcon : AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActions(BuildContext context, WidgetRef ref, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          _buildActionItem(
            icon: 'assets/images/gda_logo.png',
            title: 'GDA Vault AI',
            isDark: isDark,
            isLogo: true,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildActionItem(
            iconData: Icons.tune_rounded,
            title: 'Filter',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              ref.read(chatProvider.notifier).openFilterSheet();
            },
          ),
          const SizedBox(height: 12),
          const Divider(
            height: 1,
            indent: 12,
            endIndent: 12,
            color: Colors.white10,
          ),
          const SizedBox(height: 12),
          _buildActionItem(
            iconData: Icons.add_circle_outline_rounded,
            title: 'New Chat',
            isDark: isDark,
            onTap: () {
              ref.read(chatProvider.notifier).startNewChat();
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    String? icon,
    IconData? iconData,
    required String title,
    required bool isDark,
    bool isLogo = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.1,
                  ),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: isLogo
                    ? Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(icon!, fit: BoxFit.contain),
                      )
                    : Icon(
                        iconData,
                        size: 16,
                        color: isDark
                            ? AppColors.darkIcon
                            : AppColors.primaryBlue,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationSection(
    BuildContext context,
    ChatState state,
    WidgetRef ref,
    bool isDark,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Chats',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.4,
                ),
              ),
            ),
          ),
          Expanded(
            child: state.recentSessions.isEmpty
                ? _buildEmptyHistory(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
      ),
    );
  }

  Widget _buildEmptyHistory(bool isDark) {
    return Center(
      child: Text(
        'No recent chats',
        style: AppTextStyles.dmSans.copyWith(
          fontSize: 13,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () {
          ref.read(chatProvider.notifier).loadSession(session['id']);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? AppColors.darkCard
                      : AppColors.primaryBlue.withValues(alpha: 0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: (isDark ? Colors.white : AppColors.primaryBlue)
                        .withValues(alpha: 0.1),
                  )
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  session['title'] ?? 'Untitled Chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 14.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightText,
                  ),
                ),
              ),
              if (isSelected)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color:
                        (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightText)
                            .withValues(alpha: 0.4),
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'delete') {
                      _showDeleteDialog(
                        context,
                        ref,
                        session['id'],
                        session['title']?.toString() ?? 'Untitled Chat',
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withValues(alpha: 0.5)
            : AppColors.lightBg,
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? AppColors.primaryBlue : AppColors.secondarySlate,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Center(
              child: Icon(Icons.person_rounded, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'GDA User',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightText,
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
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete chat?',
            style: AppTextStyles.playfairDisplay.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This will permanently delete "$title" from local storage.',
            style: AppTextStyles.dmSans.copyWith(fontSize: 14),
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
