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
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2638) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.divider.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleOpenSource(context),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  // Icon Section
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color,
                          color.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Details Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          citation.fileName ?? citation.categoryName,
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.navyDark,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                citation.categoryName.toUpperCase(),
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (citation.pageNumber > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                "PAGE ${citation.pageNumber}",
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.gold,
                                  letterSpacing: 0.5,
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
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.charcoal.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: isDark ? Colors.white.withValues(alpha: 0.3) : AppColors.charcoal.withValues(alpha: 0.3),
                    ),
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
