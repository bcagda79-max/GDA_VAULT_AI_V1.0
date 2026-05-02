import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/chat_state.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/document_model.dart';

class SourceCitationCard extends ConsumerWidget {
  final SourceCitation citation;

  const SourceCitationCard({super.key, required this.citation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = citation.categoryColor ?? AppColors.navyDark;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.divider,
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleOpenSource(context),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Icon Section
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Details Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          citation.fileName ?? citation.categoryName,
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.navyDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              "Ref: ${citation.categoryName}",
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: 10,
                                color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.charcoal.withValues(alpha: 0.6),
                              ),
                            ),
                            if (citation.pageNumber > 0) ...[
                              Text(
                                " · Page ${citation.pageNumber}",
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action Icon
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: isDark ? Colors.white.withValues(alpha: 0.2) : AppColors.charcoal.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleOpenSource(BuildContext context) async {
    final storagePath = citation.storagePath ?? citation.displayPath;
    
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text("Opening reference: Page ${citation.pageNumber}..."),
          ],
        ),
        duration: const Duration(milliseconds: 1500),
      ),
    );

    try {
      // 1. Try to find document by Hierarchical Metadata (Category + Year + Filename)
      // This is more reliable than path which might differ between n8n and DB
      Map<String, dynamic>? docMap;
      
      if (citation.fileName != null) {
        docMap = await SupabaseService.instance.findDocumentByMetadata(
          categoryName: citation.categoryName,
          fileName: citation.fileName!,
          year: citation.yearLabel,
        );
      }

      // 2. Fallback to direct path search if metadata search failed
      if (docMap == null && storagePath != null) {
        docMap = await SupabaseService.instance.getDocumentByPath(storagePath);
      }
      
      if (docMap != null && context.mounted) {
        final doc = DocumentModel.fromMap(docMap);
        
        // 2. Navigate to PdfViewerScreen with initialPage
        context.push(
          '/pdf-viewer',
          extra: {
            'document': doc,
            'categoryColor': doc.categoryColor ?? citation.categoryColor ?? AppColors.navyDark,
            'categoryName': doc.categoryName ?? citation.categoryName,
            'initialPage': citation.pageNumber,
          },
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reference file not found in database. Please check categories."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening document: $e")),
        );
      }
    }
  }
}
