import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/services/api_service.dart';
import 'package:gda_vault_ai/core/services/pdf_viewer_service.dart';
import 'package:gda_vault_ai/models/document_model.dart';
import 'package:shimmer/shimmer.dart';

class YearListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final Color categoryColor;
  final int yearFrom;
  final int? yearTo;
  final String? subCategoryName;
  final String? subCategoryId;

  const YearListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.yearFrom,
    this.yearTo,
    this.subCategoryName,
    this.subCategoryId,
  });

  @override
  State<YearListScreen> createState() => _YearListScreenState();
}

class _YearListScreenState extends State<YearListScreen> {
  final _api = ApiService.instance;
  bool _isLoading = true;
  bool _isDescending = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  List<DocumentModel> _documents = const [];
  List<int> _availableYears = const [];
  List<int> _yearFolders = const [];
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rows = await _api.getDocumentsByCategory(widget.categoryId);
      List<DocumentModel> docs = rows.map(DocumentModel.fromMap).toList();

      if (widget.subCategoryId != null &&
          widget.subCategoryId!.isNotEmpty &&
          widget.subCategoryId != widget.categoryId) {
        docs = docs
            .where((d) => d.subCategoryId == widget.subCategoryId)
            .toList();
      }

      final years = docs.map((d) => d.yearStart).toSet().toList()
        ..sort((a, b) => b.compareTo(a));

      final folders = years;

      if (!mounted) return;
      setState(() {
        _documents = docs;
        _availableYears = years;
        _yearFolders = folders;
        _selectedYear = folders.isNotEmpty ? folders.first : null;
        _isLoading = false;
      });
      _sortDocuments();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _documents = const [];
        _availableYears = const [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load documents'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sortDocuments() {
    setState(() {
      _documents = [..._documents]
        ..sort(
          (a, b) => _isDescending
              ? b.yearStart.compareTo(a.yearStart)
              : a.yearStart.compareTo(b.yearStart),
        );
    });
  }

  List<DocumentModel> get _visibleDocuments {
    if (_selectedYear == null) return _documents;
    return _documents.where((doc) => doc.yearStart == _selectedYear).toList();
  }

  Future<void> _downloadDocument(DocumentModel document) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.05;
      _downloadStatus = 'Preparing download...';
    });

    final file = await PdfViewerService.instance.downloadDocument(
      document,
      onProgress: (progress, status) {
        if (!mounted) return;
        setState(() {
          _downloadProgress = progress;
          _downloadStatus = status;
        });
      },
    );

    if (!mounted) return;
    setState(() {
      _isDownloading = false;
    });

    if (file != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${document.fileName} saved offline')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getCleanTitle() {
    final title = widget.subCategoryName ?? widget.categoryName;
    if (title.contains('Board of Authority')) {
      return title.replaceFirst('Board of Authority', '').trim();
    }
    return title;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: isDark ? AppTokens.darkBgPage : AppTokens.lightBgPage,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 860;

            return Stack(
              children: [
                Column(
                  children: [
                    // HEADER
                    if (!isDesktop) _buildMobileHeader(context),
                    if (isDesktop) _buildDesktopHeader(isDark),

                    // YEAR FILTER ROW
                    _buildYearFilterRow(isDark),

                    // DOCUMENT LIST
                    Expanded(
                      child: _isLoading
                          ? _YearListLoading(isDark: isDark)
                          : _yearFolders.isEmpty
                              ? _EmptyState(onRetry: _loadDocuments)
                              : _visibleDocuments.isEmpty
                                  ? _EmptyState(
                                      onRetry: _loadDocuments,
                                      message:
                                          'No documents in ${_selectedYear ?? widget.yearFrom} yet',
                                    )
                                  : isDesktop
                                      ? _buildDesktopTable(isDark)
                                      : _buildMobileList(isDark),
                    ),
                  ],
                ),

                // Download overlay
                if (_isDownloading)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _buildDownloadOverlay(isDark),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── MOBILE HEADER ──────────────────────────────────────
  Widget _buildMobileHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56,
      color: isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back, size: 20, color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary),
          ),
          Expanded(
            child: Center(
              child: Text(
                _getCleanTitle(),
                style: AppTextStyles.headingSm.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── DESKTOP HEADER ─────────────────────────────────────
  Widget _buildDesktopHeader(bool isDark) {
    final textTertiary =
        isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final textPrimary =
        isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Pop twice to go back to categories
                  context.pop();
                  context.pop();
                },
                child: Text(
                  'Categories',
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 13,
                    color: textTertiary,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.chevron_right, size: 16, color: textTertiary),
              ),
              GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  widget.categoryName,
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 13,
                    color: textTertiary,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (widget.subCategoryName != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child:
                      Icon(Icons.chevron_right, size: 16, color: textTertiary),
                ),
                Text(
                  widget.subCategoryName!,
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 13,
                    color: isDark
                        ? AppTokens.darkTextPrimary
                        : AppTokens.lightTextPrimary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getCleanTitle(),
            style: AppTextStyles.headingLg.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── YEAR FILTER ROW ────────────────────────────────────
  Widget _buildYearFilterRow(bool isDark) {
    if (_yearFolders.isEmpty && !_isLoading) return const SizedBox.shrink();

    final textSecondary =
        isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final bgSurface =
        isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight =
        isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final brandPrimary =
        isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'YEARLY FOLDERS',
            style: AppTextStyles.labelSm.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _yearFolders.map((year) {
                  final isSelected = _selectedYear == year;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedYear = year),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? brandPrimary : bgSurface,
                          borderRadius: BorderRadius.circular(999),
                          border: isSelected
                              ? null
                              : Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
                        ),
                        child: Text(
                          '$year',
                          style: AppTextStyles.labelSm.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? (isDark ? const Color(0xFF141414) : Colors.white) : textSecondary,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
            ),
            child: Text(
              '${_yearFolders.length} Years',
              style: AppTextStyles.labelSm.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textSecondary,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MOBILE LIST ────────────────────────────────────────
  Widget _buildMobileList(bool isDark) {
    return RefreshIndicator(
      color: isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary,
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _visibleDocuments.length,
        itemBuilder: (context, index) {
          final doc = _visibleDocuments[index];
          return _DocumentRow(
            document: doc,
            categoryColor: widget.categoryColor,
            categoryName: widget.categoryName,
            onDownload: () => _downloadDocument(doc),
          )
              .animate(delay: Duration(milliseconds: index * 60))
              .fadeIn(duration: 250.ms)
              .slideY(begin: 0.04, end: 0, curve: Curves.easeOut);
        },
      ),
    );
  }

  // ── DESKTOP TABLE ──────────────────────────────────────
  Widget _buildDesktopTable(bool isDark) {
    final borderLight =
        isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final textTertiary =
        isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final bgPage = isDark ? AppTokens.darkBgPage : AppTokens.lightBgPage;
    final brandPrimary =
        isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;

    return RefreshIndicator(
      color: brandPrimary,
      onRefresh: _loadDocuments,
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            color: bgPage,
            child: Row(
              children: [
                const SizedBox(width: 54), // Icon column
                Expanded(
                  flex: 5,
                  child: Text(
                    'FILE NAME',
                    style: AppTextStyles.labelSm.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'PAGES',
                    style: AppTextStyles.labelSm.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    'UPLOAD DATE',
                    style: AppTextStyles.labelSm.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 80), // Actions column
              ],
            ),
          ),
          Container(height: 1, color: borderLight),

          // Table rows
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _visibleDocuments.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(height: 1, color: borderLight),
              ),
              itemBuilder: (context, index) {
                final doc = _visibleDocuments[index];
                return _DesktopDocumentRow(
                  document: doc,
                  categoryColor: widget.categoryColor,
                  categoryName: widget.categoryName,
                  onDownload: () => _downloadDocument(doc),
                )
                    .animate(delay: Duration(milliseconds: index * 60))
                    .fadeIn(duration: 250.ms);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── DOWNLOAD OVERLAY ───────────────────────────────────
  Widget _buildDownloadOverlay(bool isDark) {
    final bgSurface =
        isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight =
        isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final brandPrimary =
        isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgSurface,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _downloadStatus,
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _downloadProgress,
                minHeight: 5,
                backgroundColor: borderLight,
                valueColor: AlwaysStoppedAnimation(brandPrimary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(_downloadProgress * 100).clamp(0, 100).toStringAsFixed(0)}%',
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 11,
                color: brandPrimary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── MOBILE DOCUMENT ROW ──────────────────────────────────
class _DocumentRow extends StatelessWidget {
  final DocumentModel document;
  final Color categoryColor;
  final String categoryName;
  final VoidCallback onDownload;

  const _DocumentRow({
    required this.document,
    required this.categoryColor,
    required this.categoryName,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSurface =
        isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight =
        isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final textPrimary =
        isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary;
    final textSecondary =
        isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary =
        isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final brandPrimary =
        isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;
    final brandSurface =
        isDark ? AppTokens.darkBrandSurface : AppTokens.lightBrandSurface;
    final shadowXs = isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowXs;

    final pdfBg = isDark ? const Color(0xFF2D1B1B) : const Color(0xFFFEE4E2);
    const pdfIcon = Color(0xFFF04438);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          onTap: () {
            context.push(
              '/categories/sub/${document.categoryId}/years/pdf',
              extra: {
                'document': document,
                'categoryColor': categoryColor,
                'categoryName': categoryName,
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
              boxShadow: shadowXs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // PDF icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: pdfBg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    size: 20,
                    color: pdfIcon,
                  ),
                ),
                const SizedBox(width: 12),

                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.fileName,
                        style: AppTextStyles.headingSm.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.description_outlined,
                              size: 12, color: textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            '${document.pageCount ?? 0} Pages',
                            style: AppTextStyles.labelSm.copyWith(
                              fontSize: 11,
                              color: textSecondary,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.upload_outlined,
                              size: 12, color: textTertiary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              DateFormat('dd MMM yyyy')
                                  .format(document.uploadedAt),
                              style: AppTextStyles.labelSm.copyWith(
                                fontSize: 11,
                                color: textSecondary,
                                letterSpacing: 0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Actions
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: brandSurface,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(color: borderLight, width: 1),
                      ),
                      child: Icon(Icons.open_in_new,
                          size: 16, color: brandPrimary),
                    ),
                    const SizedBox(height: 6),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 18, color: textTertiary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (value) {
                        if (value == 'open') {
                          context.push(
                            '/categories/sub/${document.categoryId}/years/pdf',
                            extra: {
                              'document': document,
                              'categoryColor': categoryColor,
                              'categoryName': categoryName,
                            },
                          );
                        } else if (value == 'download') {
                          onDownload();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'open', child: Text('Open')),
                        const PopupMenuItem(
                            value: 'download', child: Text('Download')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── DESKTOP TABLE ROW ────────────────────────────────────
class _DesktopDocumentRow extends StatefulWidget {
  final DocumentModel document;
  final Color categoryColor;
  final String categoryName;
  final VoidCallback onDownload;

  const _DesktopDocumentRow({
    required this.document,
    required this.categoryColor,
    required this.categoryName,
    required this.onDownload,
  });

  @override
  State<_DesktopDocumentRow> createState() => _DesktopDocumentRowState();
}

class _DesktopDocumentRowState extends State<_DesktopDocumentRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary;
    final textSecondary =
        isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary =
        isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final brandPrimary =
        isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;
    final brandSurface =
        isDark ? AppTokens.darkBrandSurface : AppTokens.lightBrandSurface;
    final borderLight =
        isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;

    final pdfBg = isDark ? const Color(0xFF2D1B1B) : const Color(0xFFFEE4E2);
    const pdfIcon = Color(0xFFF04438);

    final hoverBg = _isHovered
        ? (isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.white.withValues(alpha: 0.03))
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.push(
            '/categories/sub/${widget.document.categoryId}/years/pdf',
            extra: {
              'document': widget.document,
              'categoryColor': widget.categoryColor,
              'categoryName': widget.categoryName,
            },
          );
        },
        child: Container(
          height: 52,
          color: hoverBg,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              // PDF icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: pdfBg,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  size: 16,
                  color: pdfIcon,
                ),
              ),
              const SizedBox(width: 22),

              // File name
              Expanded(
                flex: 5,
                child: Text(
                  widget.document.fileName,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Pages
              SizedBox(
                width: 80,
                child: Text(
                  '${widget.document.pageCount ?? 0}',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ),

              // Upload date
              SizedBox(
                width: 140,
                child: Text(
                  DateFormat('dd MMM yyyy').format(widget.document.uploadedAt),
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ),

              // Actions
              SizedBox(
                width: 80,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: brandSurface,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusSm),
                        border: Border.all(color: borderLight, width: 1),
                      ),
                      child: Icon(Icons.open_in_new,
                          size: 14, color: brandPrimary),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          size: 18, color: textTertiary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (value) {
                        if (value == 'open') {
                          context.push(
                            '/categories/sub/${widget.document.categoryId}/years/pdf',
                            extra: {
                              'document': widget.document,
                              'categoryColor': widget.categoryColor,
                              'categoryName': widget.categoryName,
                            },
                          );
                        } else if (value == 'download') {
                          widget.onDownload();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'open', child: Text('Open')),
                        const PopupMenuItem(
                            value: 'download', child: Text('Download')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── LOADING SHIMMER ──────────────────────────────────────
class _YearListLoading extends StatelessWidget {
  final bool isDark;
  const _YearListLoading({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark
          ? AppTokens.darkBorderLight
          : AppTokens.lightBorderLight.withValues(alpha: 0.55),
      highlightColor: isDark ? AppTokens.darkBgSurface : Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 72,
          decoration: BoxDecoration(
            color: isDark ? AppTokens.darkBgSurface : Colors.white,
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            border: Border.all(
              color: isDark
                  ? AppTokens.darkBorderLight
                  : AppTokens.lightBorderLight,
            ),
          ),
        ),
      ),
    );
  }
}

// ── EMPTY STATE ──────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRetry;
  final String? message;

  const _EmptyState({required this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary =
        isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final brandPrimary =
        isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'No documents found',
              style: AppTextStyles.headingSm.copyWith(
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 240,
              child: Text(
                'Upload documents to this category to get started.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 13,
                  color: brandPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
