import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/utils/responsive_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:gda_vault_ai/core/services/pdf_viewer_service.dart';
import 'package:gda_vault_ai/models/document_model.dart';

class RecentDocumentsScreen extends StatefulWidget {
  const RecentDocumentsScreen({super.key});

  @override
  State<RecentDocumentsScreen> createState() => _RecentDocumentsScreenState();
}

class _RecentDocumentsScreenState extends State<RecentDocumentsScreen> {
  bool _isLoading = true;
  List<DocumentModel> _documents = const [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final docs = await PdfViewerService.instance.getRecentlyOpenedDocuments();
    if (!mounted) return;
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  void _open(DocumentModel document) {
    context.push(
      '/categories/sub/${document.categoryId}/years/pdf',
      extra: {
        'document': document,
        'categoryColor': document.categoryColor ?? AppTokens.lightBrandPrimary,
        'categoryName': document.categoryName ?? 'Recent Documents',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTokens.darkBgPage : AppTokens.lightBgPage,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          ResponsiveAppBar.isDesktop(context)
              ? ResponsiveAppBar.desktopHeight
              : ResponsiveAppBar.mobileHeight,
        ),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppTokens.darkBgSurface, AppTokens.darkBgPage]
                    : [AppTokens.lightBrandPrimary, AppTokens.lightBrandPrimary],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: ResponsiveAppBar.isDesktop(context)
                    ? ResponsiveAppBar.desktopPadding
                    : const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Recent Documents',
                              style: AppTextStyles.headingMd.copyWith(
                                fontSize: ResponsiveAppBar.isDesktop(context)
                                    ? 22
                                    : 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'RECENTLY OPENED',
                              style: AppTextStyles.bodyMd.copyWith(
                                fontSize: ResponsiveAppBar.isDesktop(context)
                                    ? 11
                                    : 10,
                                fontWeight: FontWeight.bold,
                                color: AppTokens.lightBrandPrimary.withValues(alpha: 0.8),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 34),
                  ],
                ),
              ),
            ),
          ),
          elevation: 0,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTokens.lightBrandPrimary),
            )
          : RefreshIndicator(
              color: AppTokens.lightBrandPrimary,
              onRefresh: _loadDocuments,
              child: _documents.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 64,
                                  color: AppTokens.lightTextPrimary.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                                AppSpacing.vertical(16),
                                Text(
                                  'No recent documents',
                                  style: AppTextStyles.headingMd.copyWith(
                                    fontSize: 18,
                                    color: AppTokens.lightTextPrimary.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Open any PDF to see it here.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMd.copyWith(
                                    fontSize: 12,
                                    color: AppTokens.lightTextPrimary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _documents.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        return _RecentDocumentTile(
                          document: doc,
                          isDark: isDark,
                          onTap: () => _open(doc),
                        );
                      },
                    ),
            ),
    );
  }
}

class _RecentDocumentTile extends StatelessWidget {
  final DocumentModel document;
  final bool isDark;
  final VoidCallback onTap;

  const _RecentDocumentTile({
    required this.document,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = document.categoryColor ?? AppTokens.lightBrandPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTokens.darkBgSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTokens.lightBorderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.picture_as_pdf_rounded, color: categoryColor),
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
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTokens.lightBrandPrimary : AppTokens.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${document.categoryName ?? 'Document'} · ${document.yearLabel} · ${document.pageCount ?? 0} pages',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 11,
                        color: AppTokens.lightTextPrimary.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Opened ${DateFormat('dd MMM yyyy, hh:mm a').format(document.uploadedAt)}',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 10,
                        color: AppTokens.lightTextPrimary.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTokens.lightBrandPrimary),
            ],
          ),
        ),
      ),
    );
  }
}


