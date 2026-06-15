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
    final color = citation.categoryColor ?? AppTokens.lightBrandPrimary;

    final bgSurface = isDark ? const Color(0xFF1C1C1C) : AppTokens.lightBgSurface;
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;

    return Container(
      width: double.infinity, // Force full width
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderLight,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  // Icon Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Details Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          citation.effectiveFileName,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppTokens.lightBrandPrimary,
                            height: 1.3,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.2),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                citation.categoryName.toUpperCase(),
                                style: AppTextStyles.bodyMd.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            _buildInfoBadge(
                              icon: Icons.calendar_today_rounded,
                              label: citation.yearLabel,
                              isDark: isDark,
                            ),
                            if (citation.pageNumber > 0)
                              _buildInfoBadge(
                                icon: Icons.find_in_page_rounded,
                                label: "PAGE ${citation.pageNumber}",
                                isDark: isDark,
                                isGold: true,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Action Icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppTokens.lightBrandPrimary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                      ),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : AppTokens.lightBrandPrimary.withValues(alpha: 0.4),
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

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required bool isDark,
    bool isGold = false,
  }) {
    final color = isGold ? AppTokens.lightBrandPrimary : (isDark ? Colors.white.withValues(alpha: 0.5) : AppTokens.lightBrandPrimary.withValues(alpha: 0.5));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
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
      Map<String, dynamic>? docMap;

      // Use the robust name we've extracted
      final nameToSearch = citation.effectiveFileName;

      docMap = await SupabaseService.instance.findDocumentByMetadata(
        categoryName: citation.categoryName,
        fileName: nameToSearch,
        year: citation.yearLabel,
      );

      // 2. Fallback to direct path search if metadata search failed
      if (docMap == null && storagePath != null) {
        docMap = await SupabaseService.instance.getDocumentByPath(storagePath);
      }

      // 3. Last ditch: search by just the category and year if we have them
      // (This might return a list, but findDocumentByMetadata does its own falls)

      if (docMap != null && context.mounted) {
        final doc = DocumentModel.fromMap(docMap);

        // 2. Navigate to PdfViewerScreen with initialPage
        context.push(
          '/pdf-viewer',
          extra: {
            'document': doc,
            'categoryColor':
                doc.categoryColor ??
                citation.categoryColor ??
                AppTokens.lightBrandPrimary,
            'categoryName': doc.categoryName ?? citation.categoryName,
            'initialPage': citation.pageNumber,
          },
        );
      }
 else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Reference file not found in database. Please check categories.",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error opening document: $e")));
      }
    }
  }
}

