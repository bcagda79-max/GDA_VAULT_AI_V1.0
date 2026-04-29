import 'package:flutter/material.dart';
import '../models/chat_state.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_colors.dart';

class SourceCitationCard extends StatelessWidget {
  final SourceCitation citation;

  const SourceCitationCard({super.key, required this.citation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: citation.categoryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: citation.categoryColor.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Category color stripe
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: citation.categoryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        citation.documentName,
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.charcoal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: citation.categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        citation.yearLabel,
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: citation.categoryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      citation.categoryName,
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 9,
                        color: AppColors.charcoal.withValues(alpha: 0.45),
                      ),
                    ),
                    if (citation.pageNumbers.isNotEmpty)
                      Text(
                        " · pp. ${citation.pageNumbers.join(', ')}",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 9,
                          color: AppColors.charcoal.withValues(alpha: 0.45),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // View button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Opening ${citation.documentName}..."),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: citation.categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "View",
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: citation.categoryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
