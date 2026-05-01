// lib/features/recent_scans/recent_scans_list_screen.dart
// ignore_for_file: unused_element, unused_field, prefer_final_fields, unused_local_variable
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/features/add_document/providers/recent_scans_provider.dart';
import 'package:gda_vault_ai/models/document_model.dart';

class RecentScansListScreen extends ConsumerStatefulWidget {
  const RecentScansListScreen({super.key});

  @override
  ConsumerState<RecentScansListScreen> createState() =>
      _RecentScansListScreenState();
}

class _RecentScansListScreenState extends ConsumerState<RecentScansListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(dt);

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  List<File> _filtered(List<File> files) {
    if (_query.isEmpty) return files;
    final q = _query.toLowerCase();
    return files
        .where((f) => f.uri.pathSegments.last.toLowerCase().contains(q))
        .toList();
  }

  void _openFile(BuildContext context, File file) {
    final name = file.uri.pathSegments.last;
    final modDate = file.statSync().modified;
    final doc = DocumentModel(
      id: file.path,
      categoryId: 'scan',
      yearStart: modDate.year,
      fileName: name,
      storagePath: file.path,
      pageCount: 1,
      uploadedAt: modDate,
    );
    context.push(
      '/categories/sub/scan/years/pdf',
      extra: {
        'document': doc,
        'categoryColor': AppColors.navyDark,
        'categoryName': 'Recent Scans',
      },
    );
  }

  void _editFile(BuildContext context, File file) {
    context.push(
      '/dashboard/add/review',
      extra: {
        'pageCount': 1,
        'source': 'existing_pdf',
        'imagePaths': <String>[],
        'filePath': file.path,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncFiles = ref.watch(recentScansProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F6FA),
      appBar: _buildAppBar(isDark),
      body: asyncFiles.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.navyDark),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error loading scans: $e',
            style: AppTextStyles.dmSans.copyWith(color: Colors.red),
          ),
        ),
        data: (files) => _buildBody(context, isDark, files),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: AppColors.navyDark,
      elevation: 0,
      leading: const BackButton(color: Colors.white),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Scans',
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            'Galiyat Development Authority',
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.55),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () => ref.invalidate(recentScansProvider),
          tooltip: 'Refresh',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _buildSearchBar(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.navyDark,
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        style: AppTextStyles.dmSans.copyWith(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search scans…',
          hintStyle: AppTextStyles.dmSans.copyWith(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.white54,
            size: 20,
          ),
          suffixIcon: _query.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, List<File> allFiles) {
    final files = _filtered(allFiles);
    if (files.isEmpty) {
      return _buildEmptyState(isDark, allFiles.isEmpty);
    }
    return Column(
      children: [
        // Count bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: isDark ? AppColors.darkCard : Colors.white,
          child: Row(
            children: [
              Icon(
                Icons.folder_copy_rounded,
                size: 14,
                color: AppColors.navyDark.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                '${files.length} document${files.length == 1 ? '' : 's'}'
                '${_query.isNotEmpty ? ' found' : ' scanned locally'}',
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkText.withValues(alpha: 0.65)
                      : AppColors.charcoal.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: files.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (ctx, index) => _ScanListItem(
              file: files[index],
              isDark: isDark,
              index: index,
              formatDate: _formatDate,
              formatSize: _formatSize,
              onOpen: () => _openFile(ctx, files[index]),
              onEdit: () => _editFile(ctx, files[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, bool noFilesAtAll) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            noFilesAtAll
                ? Icons.document_scanner_outlined
                : Icons.search_off_rounded,
            size: 64,
            color: AppColors.navyDark.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            noFilesAtAll ? 'No scans yet' : 'No results for "$_query"',
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noFilesAtAll
                ? 'Tap "Add New File" on the home screen\nto scan your first document.'
                : 'Try a different search term.',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 13,
              color: AppColors.charcoal.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ScanListItem extends StatelessWidget {
  final File file;
  final bool isDark;
  final int index;
  final String Function(DateTime) formatDate;
  final String Function(int) formatSize;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  const _ScanListItem({
    required this.file,
    required this.isDark,
    required this.index,
    required this.formatDate,
    required this.formatSize,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final stat = file.statSync();
    final name = file.uri.pathSegments.last;
    final isPdf = name.toLowerCase().endsWith('.pdf');

    return GestureDetector(
      onTap: onOpen,
      child:
          Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyDark.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // File icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isPdf
                            ? AppColors.navyDark.withValues(alpha: 0.08)
                            : AppColors.gdaGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_rounded,
                        size: 26,
                        color: isPdf ? AppColors.navyDark : AppColors.gdaGreen,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.charcoal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: AppColors.charcoal.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatDate(stat.modified),
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 10,
                                  color: AppColors.charcoal.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.storage_rounded,
                                size: 11,
                                color: AppColors.charcoal.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatSize(stat.size),
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 10,
                                  color: AppColors.charcoal.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionChip(
                          icon: Icons.open_in_new_rounded,
                          label: 'Open',
                          color: AppColors.navyDark,
                          onTap: onOpen,
                        ),
                        const SizedBox(height: 6),
                        _ActionChip(
                          icon: Icons.edit_rounded,
                          label: 'Edit',
                          color: AppColors.gold,
                          onTap: onEdit,
                        ),
                      ],
                    ),
                  ],
                ),
              )
              .animate(delay: Duration(milliseconds: 50 * index))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.04, end: 0),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
