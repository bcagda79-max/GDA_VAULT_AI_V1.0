// lib/widgets/gda_doc_row.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class GdaDocRow extends StatelessWidget {
  final String filename;
  final String date;
  final bool showDivider;
  final VoidCallback? onTap;

  const GdaDocRow({
    super.key,
    required this.filename,
    required this.date,
    this.showDivider = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderLight = isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final textPrimary = isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary;
    final textTertiary = isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final statusError = isDark ? AppTokens.darkStatusError : AppTokens.lightStatusError;
    
    // Very light red background for PDF icon
    final pdfBgColor = isDark ? const Color(0xFF2D1010) : const Color(0xFFFEE4E2);

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: borderLight, width: isDark ? 0.5 : 1.0))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: pdfBgColor,
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Icon(
                Icons.picture_as_pdf,
                size: 14,
                color: isDark ? const Color(0xFFEF4444) : statusError,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filename,
                    style: AppTextStyles.labelLg.copyWith(color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: AppTextStyles.caption.copyWith(color: textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
