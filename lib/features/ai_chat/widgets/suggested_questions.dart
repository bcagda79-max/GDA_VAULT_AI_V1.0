import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

const List<String> _suggestedQuestions = [
  'What was discussed in 2006 BOA meeting?',
  'Show Trust Minutes from 1996',
  'List all Administration files',
];

class SuggestedQuestions extends ConsumerWidget {
  const SuggestedQuestions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(chatProvider);

    final bgSurface = isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight = isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _suggestedQuestions.map((question) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bgSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: borderLight,
                    width: 1,
                  ),
                ),
                child: Text(
                  question,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

