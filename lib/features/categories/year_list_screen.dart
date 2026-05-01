import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/services/supabase_service.dart';
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

  const YearListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.yearFrom,
    this.yearTo,
    this.subCategoryName,
  });

  @override
  State<YearListScreen> createState() => _YearListScreenState();
}

class _YearListScreenState extends State<YearListScreen> {
  final _supa = SupabaseService.instance;
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
      final resolvedCategoryId =
          await _supa.resolveCategoryId(widget.categoryId) ?? widget.categoryId;
      final rows = await _supa.getDocumentsByCategory(widget.categoryId);
      List<DocumentModel> docs = rows.map(DocumentModel.fromMap).toList();

      if (docs.isEmpty) {
        final offline = await PdfViewerService.instance.getOfflineDocuments();
        docs = offline
            .where(
              (record) =>
                  record.categoryId == resolvedCategoryId ||
                  record.categorySlug == widget.categoryId,
            )
            .map((record) => record.toDocumentModel())
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

  @override
  Widget build(BuildContext context) {
    final totalDocs = _documents.length;
    final totalYears = _yearFolders.length;

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.navyDark,
          leading: const BackButton(color: Colors.white),
          title: Column(
            children: [
              Text(
                widget.subCategoryName ?? widget.categoryName,
                style: AppTextStyles.playfairDisplay.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Select a year to browse',
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.sort, color: Colors.white),
              onPressed: () {
                setState(() => _isDescending = !_isDescending);
                _sortDocuments();
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _CategoryInfoHeader(
                  categoryName: widget.categoryName,
                  categoryColor: widget.categoryColor,
                  yearFrom: widget.yearFrom,
                  yearTo: widget.yearTo,
                  totalDocs: totalDocs,
                  totalYears: totalYears,
                ),
                _SortAndFilterBar(
                  yearListLength: _availableYears.length,
                  isDescending: _isDescending,
                  onSortTap: () {
                    setState(() => _isDescending = !_isDescending);
                    _sortDocuments();
                  },
                ),
                _YearFolderStrip(
                  yearFolders: _yearFolders,
                  selectedYear: _selectedYear,
                  onSelected: (year) {
                    setState(() => _selectedYear = year);
                  },
                ),
                Expanded(
                  child: _isLoading
                      ? _YearListLoading(
                          isDark:
                              Theme.of(context).brightness == Brightness.dark,
                        )
                      : _yearFolders.isEmpty
                      ? _EmptyState(onRetry: _loadDocuments)
                      : _visibleDocuments.isEmpty
                      ? _EmptyState(
                          onRetry: _loadDocuments,
                          message:
                              'No documents in ${_selectedYear ?? widget.yearFrom} yet',
                        )
                      : RefreshIndicator(
                          color: AppColors.gold,
                          onRefresh: _loadDocuments,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _visibleDocuments.length,
                            itemBuilder: (context, index) {
                              final document = _visibleDocuments[index];
                              return _YearListItem(
                                    document: document,
                                    categoryColor: widget.categoryColor,
                                    categoryName: widget.categoryName,
                                    onDownload: () =>
                                        _downloadDocument(document),
                                  )
                                  .animate(
                                    delay: Duration(milliseconds: index * 50),
                                  )
                                  .fadeIn()
                                  .slideX(begin: 0.04);
                            },
                          ),
                        ),
                ),
              ],
            ),
            if (_isDownloading)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _downloadStatus,
                          style: AppTextStyles.dmSans.copyWith(
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
                            backgroundColor: AppColors.divider,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.gold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(_downloadProgress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 11,
                            color: AppColors.charcoal.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryInfoHeader extends StatelessWidget {
  final String categoryName;
  final Color categoryColor;
  final int yearFrom;
  final int? yearTo;
  final int totalDocs;
  final int totalYears;

  const _CategoryInfoHeader({
    required this.categoryName,
    required this.categoryColor,
    required this.yearFrom,
    this.yearTo,
    required this.totalDocs,
    required this.totalYears,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [categoryColor, categoryColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: AppTextStyles.playfairDisplay.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                AppSpacing.vertical(4),
                Text(
                  '$yearFrom – ${yearTo ?? 'Ongoing'}',
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                AppSpacing.vertical(10),
                Row(
                  children: [
                    _buildChip(
                      '$totalDocs Documents',
                      Icons.folder_copy_rounded,
                    ),
                    AppSpacing.horizontal(8),
                    _buildChip('$totalYears Years', Icons.date_range_rounded),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.folder_rounded,
            size: 36,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.white),
          AppSpacing.horizontal(4),
          Text(
            label,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 10,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SortAndFilterBar extends StatelessWidget {
  final int yearListLength;
  final bool isDescending;
  final VoidCallback onSortTap;

  const _SortAndFilterBar({
    required this.yearListLength,
    required this.isDescending,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$yearListLength Years Available',
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.55),
            ),
          ),
          GestureDetector(
            onTap: onSortTap,
            child: Row(
              children: [
                const Icon(Icons.sort, size: 16, color: AppColors.gdaGold),
                AppSpacing.horizontal(4),
                Text(
                  isDescending ? 'Newest First' : 'Oldest First',
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 11,
                    color: AppColors.gdaGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _YearFolderStrip extends StatelessWidget {
  final List<int> yearFolders;
  final int? selectedYear;
  final ValueChanged<int> onSelected;

  const _YearFolderStrip({
    required this.yearFolders,
    required this.selectedYear,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (yearFolders.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 116,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: yearFolders.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final year = yearFolders[index];
          final isSelected = selectedYear == year;
          return GestureDetector(
            onTap: () => onSelected(year),
            child: Container(
              width: 134,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [
                          AppColors.navyDark,
                          AppColors.navyDark.withValues(alpha: 0.88),
                        ]
                      : [Colors.white, Colors.white],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.gdaGold.withValues(alpha: 0.45)
                      : AppColors.divider,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isSelected ? 0.16 : 0.06,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.14)
                          : AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.folder_rounded,
                      color: isSelected ? Colors.white : AppColors.gold,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$year',
                          style: AppTextStyles.playfairDisplay.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Folder',
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.75)
                                : AppColors.charcoal.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _YearListItem extends StatelessWidget {
  final DocumentModel document;
  final Color categoryColor;
  final String categoryName;
  final VoidCallback onDownload;

  const _YearListItem({
    required this.document,
    required this.categoryColor,
    required this.categoryName,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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
          child: IntrinsicHeight(
            child: Row(
              children: [
                _LeftYearBand(
                  yearStart: document.yearStart,
                  yearEnd: document.yearEnd,
                  categoryColor: categoryColor,
                ),
                _Content(document: document, categoryColor: categoryColor),
                _RightPdfMenu(
                  document: document,
                  categoryColor: categoryColor,
                  onDownload: onDownload,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeftYearBand extends StatelessWidget {
  final int yearStart;
  final int? yearEnd;
  final Color categoryColor;

  const _LeftYearBand({
    required this.yearStart,
    this.yearEnd,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          bottomLeft: Radius.circular(14),
        ),
        border: Border(
          right: BorderSide(
            color: categoryColor.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              yearStart.toString(),
              style: AppTextStyles.playfairDisplay.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: categoryColor,
              ),
            ),
            if (yearEnd != null && yearEnd != yearStart) ...[
              Container(
                height: 16,
                width: 1.5,
                color: categoryColor.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(vertical: 2),
              ),
              Text(
                yearEnd.toString(),
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 10,
                  color: categoryColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final DocumentModel document;
  final Color categoryColor;

  const _Content({required this.document, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (document.isOngoing) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gdaGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.gdaGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        AppSpacing.horizontal(4),
                        Text(
                          'ONGOING',
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gdaGreen,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.horizontal(8),
                ],
                Expanded(
                  child: Text(
                    document.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vertical(5),
            Row(
              children: [
                Icon(
                  Icons.description_rounded,
                  size: 12,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.4,
                  ),
                ),
                AppSpacing.horizontal(4),
                Text(
                  '${document.pageCount ?? 0} pages',
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.45,
                    ),
                  ),
                ),
                AppSpacing.horizontal(14),
                Icon(
                  Icons.upload_rounded,
                  size: 12,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.4,
                  ),
                ),
                AppSpacing.horizontal(4),
                Text(
                  DateTime.tryParse(document.uploadedAt.toIso8601String()) ==
                          null
                      ? ''
                      : DateFormat('dd MMM yyyy').format(document.uploadedAt),
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.45,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vertical(6),
            Container(
              height: 3,
              width: 80,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                widthFactor: 0.6,
                child: Container(
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RightPdfBadge extends StatelessWidget {
  final Color categoryColor;
  const _RightPdfBadge({required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: categoryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PDF',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: categoryColor,
                letterSpacing: 0.5,
              ),
            ),
            Icon(Icons.picture_as_pdf_rounded, size: 16, color: categoryColor),
          ],
        ),
      ),
    );
  }
}

class _RightPdfMenu extends StatelessWidget {
  final DocumentModel document;
  final Color categoryColor;
  final VoidCallback onDownload;

  const _RightPdfMenu({
    required this.document,
    required this.categoryColor,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: categoryColor),
            onSelected: (value) {
              if (value == 'open') {
                context.push(
                  '/categories/sub/${document.categoryId}/years/pdf',
                  extra: {
                    'document': document,
                    'categoryColor': categoryColor,
                    'categoryName': document.categoryName ?? 'Documents',
                  },
                );
                return;
              }
              if (value == 'download') {
                onDownload();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem<String>(value: 'open', child: Text('Open')),
              const PopupMenuItem<String>(
                value: 'download',
                child: Text('Download'),
              ),
            ],
          ),
          _RightPdfBadge(categoryColor: categoryColor),
        ],
      ),
    );
  }
}

class _YearListLoading extends StatelessWidget {
  final bool isDark;
  const _YearListLoading({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark
          ? AppColors.darkCard.withValues(alpha: 0.9)
          : AppColors.divider.withValues(alpha: 0.55),
      highlightColor: isDark ? AppColors.darkSurface : Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 94,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRetry;
  final String? message;

  const _EmptyState({required this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.2),
          ),
          AppSpacing.vertical(16),
          Text(
            message ?? 'No documents yet',
            style: AppTextStyles.playfairDisplay.copyWith(
              fontSize: 18,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
            ),
          ),
          Text(
            'Documents added via Scan or Upload\nwill appear here',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 13,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 13,
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
