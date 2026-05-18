import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/utils/responsive_app_bar.dart';
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
      final rows = await _supa.getDocumentsByCategory(widget.categoryId);
      List<DocumentModel> docs = rows.map(DocumentModel.fromMap).toList();

      // Filter by sub-category on the Dart side to be 100% sure we don't miss anything
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: true,
      child: Scaffold(
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
                      ? [AppColors.darkSurface, AppColors.darkBg]
                      : [AppColors.navyDark, AppColors.navyMid],
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
                      : ResponsiveAppBar.mobilePadding,
                  child: Row(
                    children: [
                      // Far left icon
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      // Centered Title
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _getCleanTitle(),
                              style: AppTextStyles.playfairDisplay.copyWith(
                                fontSize: ResponsiveAppBar.isDesktop(context)
                                    ? 20
                                    : 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      // Right-side spacer
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),
            ),
            elevation: 0,
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: isLandscape ? 4 : 10),
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
                              horizontal: 10,
                              vertical: 8,
                            ),
                            itemCount: _visibleDocuments.length,
                            itemBuilder: (context, index) {
                              final document = _visibleDocuments[index];
                              return _YearListItem(
                                document: document,
                                categoryColor: widget.categoryColor,
                                categoryName: widget.categoryName,
                                onDownload: () => _downloadDocument(document),
                              );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isLandscape ? 8 : 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "YEARLY FOLDERS",
            style: AppTextStyles.dmSans.copyWith(
              fontSize: isLandscape ? 9 : 10,
              fontWeight: FontWeight.w900,
              color: AppColors.gold,
              letterSpacing: 1.5,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.navyDark.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$yearListLength Years',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: isLandscape ? 9 : 10,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppColors.navyDark.withValues(alpha: 0.5),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isDesktop = ResponsiveAppBar.isDesktop(context);
    final stripHeight = isDesktop ? 112.0 : (isLandscape ? 72.0 : 96.0);
    final chipWidth = isDesktop ? 96.0 : (isLandscape ? 66.0 : 78.0);
    final chipPadding = isDesktop ? 12.0 : (isLandscape ? 8.0 : 10.0);
    final chipRadius = isDesktop ? 20.0 : 16.0;
    final yearFontSize = isDesktop ? 17.0 : (isLandscape ? 14.0 : 15.0);

    return Container(
      height: stripHeight,
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        bottom: isLandscape ? 8 : 12,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: yearFolders.length,
        separatorBuilder: (_, _) => SizedBox(width: isLandscape ? 8 : 12),
        itemBuilder: (context, index) {
          final year = yearFolders[index];
          final isSelected = selectedYear == year;
          return GestureDetector(
            onTap: () => onSelected(year),
            child: Container(
              width: chipWidth,
              padding: EdgeInsets.all(chipPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [AppColors.navyDark, AppColors.navyMid]
                      : [
                          isDark ? const Color(0xFF1E2638) : Colors.white,
                          isDark ? const Color(0xFF161E35) : Colors.white,
                        ],
                ),
                borderRadius: BorderRadius.circular(chipRadius),
                border: Border.all(
                  color: isSelected
                      ? AppColors.gold.withValues(alpha: 0.4)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.divider.withValues(alpha: 0.5)),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isSelected ? 0.25 : 0.05,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$year',
                  style: AppTextStyles.numberStyle(
                    fontSize: yearFontSize,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppColors.navyDark),
                    letterSpacing: 0.4,
                  ),
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2638) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.divider.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
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
  final Color categoryColor;

  const _LeftYearBand({required this.yearStart, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            categoryColor.withValues(alpha: 0.15),
            categoryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          bottomLeft: Radius.circular(22),
        ),
        border: Border(
          right: BorderSide(
            color: categoryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "YEAR",
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: categoryColor.withValues(alpha: 0.5),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              yearStart.toString(),
              style: AppTextStyles.numberStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : categoryColor,
                letterSpacing: -0.5,
              ),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document.fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.navyDark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_rounded,
                      size: 12,
                      color: AppColors.gold.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${document.pageCount ?? 0} Pages',
                      style: AppTextStyles.numberStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppColors.charcoal.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.upload_rounded,
                      size: 12,
                      color: AppColors.gold.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(document.uploadedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.numberStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : AppColors.charcoal.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 100,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : categoryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.7,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor,
                        categoryColor.withValues(alpha: 0.7),
                      ],
                    ),
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
