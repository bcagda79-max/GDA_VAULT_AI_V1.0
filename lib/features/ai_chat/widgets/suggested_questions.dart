import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

const List<String> _suggestedQuestions = [
  'When was the land trust formed?',
  'What does Resolution 47 say?',
  'Show Plot 47-A records',
  'Latest board resolutions 2024',
  'Admin orders about staff transfers',
  'Private property transfers in 2008',
];

class SuggestedQuestions extends ConsumerWidget {
  const SuggestedQuestions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(chatProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Try asking:",
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal.withValues(alpha: 0.4),
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedQuestions.map((question) {
              return GestureDetector(
                onTap: () {
                  final notifier = ref.read(chatProvider.notifier);
                  notifier.updateInput(question);
                  if (chatState.categoriesSelected) {
                    notifier.sendMessage(question);
                  } else {
                    // Auto-select all if nothing selected to help the user
                    notifier.selectAllCategories();
                    notifier.sendMessage(question);
                  }
                },
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.divider, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDark.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 13,
                        color: AppColors.charcoal.withValues(alpha: 0.35),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          question,
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 12,
                            color: AppColors.charcoal.withValues(alpha: 0.65),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
