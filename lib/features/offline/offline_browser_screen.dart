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
  
  // For files view
  List<OfflineDocumentRecord> _filteredFiles = [];

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
      
      // Initialize standard subcategories for Board of Authority to ensure they always show up
      if (widget.categoryId == SupabaseConstants.idBoardOfAuthority) {
        _subCategoryGroups["Board Authority Minutes (1996-2026)"] = [];
        _subCategoryGroups["Trust Minutes Archive (1961-1996)"] = [];
      }
      
      for (final r in _allRecords) {
        final key = r.categoryName;
        if (key.isNotEmpty && key != widget.categoryName) {
           _subCategoryGroups.putIfAbsent(key, () => []).add(r);
        } else {
           // Fallback grouping
           _subCategoryGroups.putIfAbsent("General", () => []).add(r);
        }
      }
    } else if (widget.viewType == OfflineBrowserViewType.years) {
      _yearGroups.clear();
      var records = _allRecords;
      if (widget.subCategoryName != null) {
        records = records.where((r) => r.categoryName == widget.subCategoryName).toList();
      }
      for (final r in records) {
        _yearGroups.putIfAbsent(r.yearStart, () => []).add(r);
      }
    } else {
      _filteredFiles = _allRecords.where((r) {
        bool match = true;
        if (widget.subCategoryName != null) {
          match = match && (r.categoryName == widget.subCategoryName);
        }
        if (widget.year != null) {
          match = match && (r.yearStart == widget.year);
        }
        return match;
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _getDisplayTitle();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
      body: Stack(
        children: [
          _buildBackgroundGlows(isDark),
          Column(
            children: [
              _buildHeader(context, isDark, title),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                    : _buildContent(isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDisplayTitle() {
    if (widget.viewType == OfflineBrowserViewType.subcategories) return widget.categoryName;
    if (widget.viewType == OfflineBrowserViewType.years) return widget.subCategoryName ?? widget.categoryName;
    if (widget.viewType == OfflineBrowserViewType.files) return "${widget.year ?? ''} Documents";
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

  Widget _buildHeader(BuildContext context, bool isDark, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.navyDark, AppColors.navyDark.withValues(alpha: 0.8)]
              : [AppColors.navyDark, AppColors.navyLight],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: isDark ? 0.5 : 0.24),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                title,
                style: AppTextStyles.playfairDisplay.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'OFFLINE ARCHIVE',
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 9,
              color: AppColors.gdaGold.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildContent(bool isDark) {
    if (widget.viewType == OfflineBrowserViewType.subcategories) {
      return _buildFolderList(
        isDark,
        _subCategoryGroups.keys.toList(),
        (name) => _subCategoryGroups[name]?.length ?? 0,
        (name) => _navigateToYears(name),
      );
    } else if (widget.viewType == OfflineBrowserViewType.years) {
      final sortedYears = _yearGroups.keys.toList()..sort((a, b) => b.compareTo(a));
      return _buildYearGrid(isDark, sortedYears);
    } else {
      return _buildFileList(isDark);
    }
  }

  Widget _buildFolderList(bool isDark, List<String> names, int Function(String) getCount, void Function(String) onTap) {
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

  Widget _buildFolderItem(bool isDark, String name, int count, int index, VoidCallback onTap) {
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
                  child: Icon(Icons.folder_rounded, color: widget.categoryColor, size: 24),
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
                          color: (isDark ? Colors.white : AppColors.navyDark).withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.gold.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.05);
  }

  Widget _buildYearGrid(bool isDark, List<int> years) {
    if (years.isEmpty) return _buildEmptyState(isDark);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final count = _yearGroups[year]?.length ?? 0;
        return _buildYearCard(isDark, year, count, index);
      },
    );
  }

  Widget _buildYearCard(bool isDark, int year, int count, int index) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.categoryColor.withValues(alpha: isDark ? 0.3 : 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToFiles(year),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$year",
                  style: AppTextStyles.playfairDisplay.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$count files",
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildFileList(bool isDark) {
    if (_filteredFiles.isEmpty) return _buildEmptyState(isDark);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final record = _filteredFiles[index];
        return _buildFileItem(isDark, record, index);
      },
    );
  }

  Widget _buildFileItem(bool isDark, OfflineDocumentRecord record, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPdf(record),
          onLongPress: () => _showDeleteDialog(record),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.fileName,
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.navyDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Downloaded: ${record.downloadedAt.day}/${record.downloadedAt.month}/${record.downloadedAt.year}",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 10,
                          color: (isDark ? Colors.white : AppColors.navyDark).withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  onPressed: () => _showDeleteDialog(record),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.gold, size: 20),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1);
  }

  Future<void> _showDeleteDialog(OfflineDocumentRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove File"),
        content: Text("Are you sure you want to remove '${record.fileName}' from offline storage?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
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
          Icon(Icons.folder_open_rounded, size: 64, color: AppColors.divider.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            "No offline files found here",
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 16,
              color: (isDark ? Colors.white : AppColors.navyDark).withValues(alpha: 0.5),
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

  void _navigateToFiles(int year) {
    context.push(
      '/dashboard/offline-documents/files/${widget.categoryId}',
      extra: {
        'categoryName': widget.categoryName,
        'categoryColor': widget.categoryColor,
        'subCategoryName': widget.subCategoryName,
        'year': year,
        'viewType': OfflineBrowserViewType.files,
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
