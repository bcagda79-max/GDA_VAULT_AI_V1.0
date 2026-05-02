import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/chat_provider.dart';
import '../models/chat_state.dart';

class AiChatDrawer extends ConsumerWidget {
  const AiChatDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header / New Chat
            _buildHeader(ref, isDark),
            
            const Divider(height: 1, color: AppColors.divider),
            
            // Recent Chats List
            Expanded(
              child: _buildRecentList(chatState, ref, isDark),
            ),
            
            const Divider(height: 1, color: AppColors.divider),
            
            // Bottom Actions
            _buildBottomActions(context, ref, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.auto_awesome, size: 16, color: AppColors.gold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "GDA Vault AI",
                style: AppTextStyles.playfairDisplay.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.navyDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // New Chat Button (Gemini Style)
          InkWell(
            onTap: () {
              ref.read(chatProvider.notifier).startNewChat();
              Navigator.pop(ref.context); // Close drawer
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.navyDark.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_rounded, size: 20, color: isDark ? AppColors.gold : AppColors.navyDark),
                  const SizedBox(width: 12),
                  Text(
                    "New Chat",
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.navyDark,
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

  Widget _buildRecentList(ChatState state, WidgetRef ref, bool isDark) {
    final sessions = state.recentSessions;

    if (sessions.isEmpty) {
      return Center(
        child: Text(
          "No recent chats",
          style: AppTextStyles.dmSans.copyWith(
            fontSize: 12,
            color: isDark ? Colors.white.withValues(alpha: 0.3) : AppColors.charcoal.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final isSelected = state.sessionId == session['id'];
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: InkWell(
            onTap: () {
              ref.read(chatProvider.notifier).loadSession(session['id']);
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isDark ? AppColors.gold.withValues(alpha: 0.1) : AppColors.navyDark.withValues(alpha: 0.05))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: isSelected ? AppColors.gold : (isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.charcoal.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      session['title'] ?? "Untitled Chat",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected 
                            ? (isDark ? Colors.white : AppColors.navyDark)
                            : (isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.charcoal),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz_rounded, size: 16),
                      padding: EdgeInsets.zero,
                      onSelected: (val) {
                        if (val == 'delete') {
                          ref.read(chatProvider.notifier).deleteSession(session['id']);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text("Delete", style: TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions(BuildContext context, WidgetRef ref, bool isDark) {
    return Column(
      children: [
        _DrawerTile(
          icon: Icons.category_outlined,
          label: "Archives Selection",
          onTap: () {
            Navigator.pop(context);
            // Trigger the existing category sheet from chat screen context
            // We'll add a callback or use a global key if needed, 
            // but for now, we can just close drawer and user can tap the top chip.
          },
          isDark: isDark,
        ),
        _DrawerTile(
          icon: Icons.settings_outlined,
          label: "AI Settings",
          onTap: () {
            Navigator.pop(context);
          },
          isDark: isDark,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.navyDark.withValues(alpha: 0.6)),
      title: Text(
        label,
        style: AppTextStyles.dmSans.copyWith(
          fontSize: 14,
          color: isDark ? Colors.white : AppColors.charcoal,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
