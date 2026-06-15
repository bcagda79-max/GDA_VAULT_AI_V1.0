import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gda_vault_ai/models/document_model.dart';

class RecentDocRow extends StatelessWidget {
  final DocumentModel document;
  final bool isDark;
  final VoidCallback onTap;

  const RecentDocRow({
    super.key,
    required this.document,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? const Color(0xFF272727) : const Color(0xFFE2E8F0);
    final textPrimary =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textHint =
        isDark ? const Color(0xFF4A5568) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: borderColor, width: isDark ? 0.5 : 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D1010) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                size: 14,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(document.uploadedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: textHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: textHint,
            ),
          ],
        ),
      ),
    );
  }
}

