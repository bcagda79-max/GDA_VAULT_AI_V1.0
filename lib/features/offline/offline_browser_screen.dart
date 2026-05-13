import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/constants/supabase_constants.dart';
import 'package:gda_vault_ai/core/services/pdf_viewer_service.dart';

enum OfflineBrowserViewType { subcategories, years, files }

class OfflineBrowserScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final Color categoryColor;
  final OfflineBrowserViewType viewType;
  final String? subCategoryId;
  final String? subCategoryName;
  final int? year;

  const OfflineBrowserScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.viewType,
    this.subCategoryId,
    this.subCategoryName,
    this.year,
  });

  @override
  State<OfflineBrowserScreen> createState() => _OfflineBrowserScreenState();
}

class _OfflineBrowserScreenState extends State<OfflineBrowserScreen> {
  bool _isLoading = true;
  List<OfflineDocumentRecord> _allRecords = [];

  // For subcategories view
  final Map<String, List<OfflineDocumentRecord>> _subCategoryGroups = {};

  // For years view
  final Map<int, List<OfflineDocumentRecord>> _yearGroups = {};

  int? _selectedYear;
  bool _isDescending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final records = await PdfViewerService.instance.getOfflineDocuments();

    // Filter by main category, including subcategories for Board of Authority
    final catRecords = records.where((r) {
      if (widget.categoryId == SupabaseConstants.idBoardOfAuthority) {
        return r.categoryId == SupabaseConstants.idBoardOfAuthority ||
            r.categoryId == SupabaseConstants.idBoardAuthorityMinutes ||
            r.categoryId == SupabaseConstants.idTrustMinutes;
      }
      return r.categoryId == widget.categoryId;
    }).toList();

    setState(() {
      _allRecords = catRecords;
      _isLoading = false;
      _applyViewFilter();
    });
  }

  void _applyViewFilter() {
    if (widget.viewType == OfflineBrowserViewType.subcategories) {
      _subCategoryGroups.clear();

      for (final r in _allRecords) {
        String subName = r.categoryName;

        // Robust mapping: Use subCategoryId if available, otherwise fallback to localPath
        if (r.subCategoryId == SupabaseConstants.idBoardAuthorityMinutes ||
            r.localPath.contains('board-authority-minutes')) {
          subName = 'Minutes 1996-2026';
        } else if (r.subCategoryId == SupabaseConstants.idTrustMinutes ||
            r.localPath.contains('trust-minutes')) {
          subName = 'Trust Minutes Archive (1961-1996)';
        }

        // Only group if the resolved subName is different from the main category
        if (subName.isNotEmpty && subName != widget.categoryName) {
          _subCategoryGroups.putIfAbsent(subName, () => []).add(r);
        }
      }

      // If after grouping we have no subcategories but we are in subcategories view,
      // it might mean all files are top-level. This shouldn't happen with the new navigation logic,
      // but as a fallback, we group them under the main category name if needed or just show empty.
    } else if (widget.viewType == OfflineBrowserViewType.years) {
      _yearGroups.clear();
      var records = _allRecords;
      if (widget.subCategoryName != null) {
        records = records.where((r) {
          String subName = r.categoryName;
          if (r.subCategoryId == SupabaseConstants.idBoardAuthorityMinutes ||
              r.localPath.contains('board-authority-minutes')) {
            subName = 'Minutes 1996-2026';
          } else if (r.subCategoryId == SupabaseConstants.idTrustMinutes ||
              r.localPath.contains('trust-minutes')) {
            subName = 'Trust Minutes Archive (1961-1996)';
          }
          return subName == widget.subCategoryName;
        }).toList();
      } else {
        // If subCategoryName is null, it means we jumped straight to years from a category.
        // We should show all records for this category.
      }
      for (final r in records) {
        _yearGroups.putIfAbsent(r.yearStart, () => []).add(r);
      }
      if (_yearGroups.isNotEmpty && _selectedYear == null) {
        final sortedYears = _yearGroups.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        _selectedYear = sortedYears.first;
      }
    } else {
      final filteredFiles = _allRecords.where((r) {
        bool match = true;
        if (widget.subCategoryName != null) {
          String subName = r.categoryName;
          if (r.subCategoryId == SupabaseConstants.idBoardAuthorityMinutes ||
              r.localPath.contains('board-authority-minutes')) {
            subName = 'Minutes 1996-2026';
          } else if (r.subCategoryId == SupabaseConstants.idTrustMinutes ||
              r.localPath.contains('trust-minutes')) {
            subName = 'Trust Minutes Archive (1961-1996)';
          }
          match = match && (subName == widget.subCategoryName);
        }
        if (widget.year != null) {
          match = match && (r.yearStart == widget.year);
        }
        return match;
      }).toList();

      if (filteredFiles.isNotEmpty && _selectedYear == null) {
        _selectedYear = filteredFiles.first.yearStart;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _getDisplayTitle();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76.0),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              title,
                              style: AppTextStyles.playfairDisplay.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'OFFLINE ARCHIVE',
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gdaGold.withValues(alpha: 0.8),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 34), // Balance the back button
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
          _buildBackgroundGlows(isDark),
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    : _buildContent(isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDisplayTitle() {
    if (widget.viewType == OfflineBrowserViewType.subcategories)
      return widget.categoryName;
    if (widget.viewType == OfflineBrowserViewType.years)
      return widget.subCategoryName ?? widget.categoryName;
    if (widget.viewType == OfflineBrowserViewType.files)
      return "${widget.year ?? ''} Documents";
    return "Offline Browser";
  }

  Widget _buildBackgroundGlows(bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          left: -50,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.categoryColor.withValues(alpha: isDark ? 0.12 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    if (widget.viewType == OfflineBrowserViewType.subcategories) {
      return _buildFolderList(
        isDark,
        _subCategoryGroups.keys.toList(),
        (name) => _subCategoryGroups[name]?.length ?? 0,
        (name) => _navigateToYears(name),
      );
    } else {
      return _buildCombinedYearFilesView(isDark);
    }
  }

  Widget _buildFolderList(
    bool isDark,
    List<String> names,
    int Function(String) getCount,
    void Function(String) onTap,
  ) {
    if (names.isEmpty) return _buildEmptyState(isDark);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: names.length,
      itemBuilder: (context, index) {
        final name = names[index];
        final count = getCount(name);
        return _buildFolderItem(isDark, name, count, index, () => onTap(name));
      },
    );
  }

  Widget _buildFolderItem(
    bool isDark,
    String name,
    int count,
    int index,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.categoryColor.withValues(alpha: isDark ? 0.2 : 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    color: widget.categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.playfairDisplay.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$count offline documents",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 12,
                          color: (isDark ? Colors.white : AppColors.navyDark)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.gold.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.05);
  }

  Widget _buildCombinedYearFilesView(bool isDark) {
    final sortedYears = _yearGroups.keys.toList()
      ..sort((a, b) => _isDescending ? b.compareTo(a) : a.compareTo(b));

    if (sortedYears.isEmpty) return _buildEmptyState(isDark);

    final currentFiles = _yearGroups[_selectedYear] ?? [];

    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "YEARLY FOLDERS",
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                  letterSpacing: 1.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _isDescending = !_isDescending);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.navyDark.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isDescending
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        size: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppColors.navyDark.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${sortedYears.length} Years',
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppColors.navyDark.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 120,
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 12),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sortedYears.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final year = sortedYears[index];
              final isSelected = _selectedYear == year;
              return GestureDetector(
                onTap: () => setState(() => _selectedYear = year),
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.all(12),
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
                    borderRadius: BorderRadius.circular(22),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppColors.gold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.folder_rounded,
                          color: isSelected ? Colors.white : AppColors.gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$year',
                        style: AppTextStyles.numberStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppColors.navyDark),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: currentFiles.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  itemCount: currentFiles.length,
                  itemBuilder: (context, index) {
                    final record = currentFiles[index];
                    return _buildFileItem(isDark, record, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFileItem(
    bool isDark,
    OfflineDocumentRecord document,
    int index,
  ) {
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
          onTap: () => _openPdf(document),
          onLongPress: () => _showDeleteDialog(document),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.categoryColor.withValues(alpha: 0.15),
                        widget.categoryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                    ),
                    border: Border(
                      right: BorderSide(
                        color: widget.categoryColor.withValues(alpha: 0.2),
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
                            color: widget.categoryColor.withValues(alpha: 0.5),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          document.yearStart.toString(),
                          style: AppTextStyles.numberStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : widget.categoryColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
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
                                        : AppColors.charcoal.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.offline_pin_rounded,
                                  size: 12,
                                  color: AppColors.gold.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Offline',
                                  style: AppTextStyles.numberStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : AppColors.charcoal.withValues(
                                            alpha: 0.5,
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
                                : widget.categoryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.categoryColor,
                                    widget.categoryColor.withValues(alpha: 0.7),
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
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: widget.categoryColor,
                    ),
                    onSelected: (value) {
                      if (value == 'delete') _showDeleteDialog(document);
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Remove File",
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.04);
  }

  Future<void> _showDeleteDialog(OfflineDocumentRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove File"),
        content: Text(
          "Are you sure you want to remove '${record.fileName}' from offline storage?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PdfViewerService.instance.removeOfflineDocument(record.storagePath);
      _loadData(); // Refresh list
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 64,
            color: AppColors.divider.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No offline files found here",
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 16,
              color: (isDark ? Colors.white : AppColors.navyDark).withValues(
                alpha: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToYears(String subCatName) {
    context.push(
      '/dashboard/offline-documents/sub/${widget.categoryId}',
      extra: {
        'categoryName': widget.categoryName,
        'categoryColor': widget.categoryColor,
        'subCategoryName': subCatName,
        'viewType': OfflineBrowserViewType.years,
      },
    );
  }

  void _openPdf(OfflineDocumentRecord record) {
    context.push(
      '/categories/sub/${record.categoryId}/years/pdf',
      extra: {
        'document': record.toDocumentModel(),
        'categoryColor': widget.categoryColor,
        'categoryName': widget.categoryName,
      },
    );
  }
}
