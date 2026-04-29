// lib/features/categories/year_list_screen.dart

/// Displays a list of documents for a given category/sub-category, grouped by year.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/data/mock_data.dart';
import 'package:gda_vault_ai/models/document_model.dart';
import 'package:intl/intl.dart';

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
  late List<DocumentModel> _documents;
  bool _isDescending = true;

  @override
  void initState() {
    super.initState();
    _documents = MockData.getDocumentsForCategory(widget.categoryId);
    _sortDocuments();
  }

  void _sortDocuments() {
    _documents.sort((a, b) {
      if (_isDescending) {
        return b.yearStart.compareTo(a.yearStart);
      } else {
        return a.yearStart.compareTo(b.yearStart);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalDocs = _documents.length;
    final totalYears = _documents.map((d) => d.yearStart).toSet().length;

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
                "Select a year to browse",
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.sort, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isDescending = !_isDescending;
                  _sortDocuments();
                });
              },
            ),
          ],
        ),
        body: Column(
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
              yearListLength: _documents.length,
              isDescending: _isDescending,
              onSortTap: () {
                setState(() {
                  _isDescending = !_isDescending;
                  _sortDocuments();
                });
              },
            ),
            Expanded(
              child: _documents.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final document = _documents[index];
                        return _YearListItem(
                              document: document,
                              categoryColor: widget.categoryColor,
                              categoryName: widget.categoryName,
                            )
                            .animate(delay: Duration(milliseconds: index * 50))
                            .fadeIn()
                            .slideX(begin: 0.04);
                      },
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
          colors: [categoryColor, categoryColor.withOpacity(0.7)],
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
                  "$yearFrom – ${yearTo ?? 'Ongoing'}",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                AppSpacing.vertical(10),
                Row(
                  children: [
                    _buildChip(
                      "$totalDocs Documents",
                      Icons.folder_copy_rounded,
                    ),
                    AppSpacing.horizontal(8),
                    _buildChip("$totalYears Years", Icons.date_range_rounded),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            MockData.categories
                .firstWhere((c) => c.name == categoryName)
                .iconData,
            size: 36,
            color: Colors.white.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
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
            "$yearListLength Years Available",
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.55),
            ),
          ),
          GestureDetector(
            onTap: onSortTap,
            child: Row(
              children: [
                const Icon(Icons.sort, size: 16, color: AppColors.gdaGold),
                AppSpacing.horizontal(4),
                Text(
                  isDescending ? "Newest First" : "Oldest First",
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

class _YearListItem extends StatelessWidget {
  final DocumentModel document;
  final Color categoryColor;
  final String categoryName;

  const _YearListItem({
    required this.document,
    required this.categoryColor,
    required this.categoryName,
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
            color: AppColors.navyDark.withOpacity(0.05),
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
                _RightPdfBadge(categoryColor: categoryColor),
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
        color: categoryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          bottomLeft: Radius.circular(14),
        ),
        border: Border(
          right: BorderSide(color: categoryColor.withOpacity(0.2), width: 0.8),
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
                color: categoryColor.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(vertical: 2),
              ),
              Text(
                yearEnd.toString(),
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 10,
                  color: categoryColor.withOpacity(0.6),
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
                      color: AppColors.gdaGreen.withOpacity(0.12),
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
                          "ONGOING",
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
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
                ),
                AppSpacing.horizontal(4),
                Text(
                  "${document.pageCount} pages",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.45),
                  ),
                ),
                AppSpacing.horizontal(14),
                Icon(
                  Icons.upload_rounded,
                  size: 12,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
                ),
                AppSpacing.horizontal(4),
                Text(
                  DateFormat("dd MMM yyyy").format(document.uploadedAt),
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.45),
                  ),
                ),
              ],
            ),
            AppSpacing.vertical(6),
            Container(
              height: 3,
              width: 80,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.08),
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
          color: categoryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "PDF",
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

class _EmptyState extends StatelessWidget {
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
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.2),
          ),
          AppSpacing.vertical(16),
          Text(
            "No documents yet",
            style: AppTextStyles.playfairDisplay.copyWith(
              fontSize: 18,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
            ),
          ),
          Text(
            "Documents added via Scan or Upload\nwill appear here",
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 13,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}
