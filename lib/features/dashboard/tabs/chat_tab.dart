// lib/features/dashboard/tabs/chat_tab.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

/// Placeholder tab for the AI Chat feature.
class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_rounded,
            size: 64,
            color: isDark
                ? AppColors.darkText.withOpacity(0.5)
                : AppColors.navyDark.withOpacity(0.7),
          ),
          const SizedBox(height: 20),
          Text(
            "AI Chat",
            style: AppTextStyles.headlineMedium.copyWith(
              color: isDark ? AppColors.darkText : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Coming in the next step",
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
