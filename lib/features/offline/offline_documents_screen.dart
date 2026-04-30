import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/services/pdf_viewer_service.dart';

class OfflineDocumentsScreen extends StatefulWidget {
  const OfflineDocumentsScreen({super.key});

  @override
  State<OfflineDocumentsScreen> createState() => _OfflineDocumentsScreenState();
}

class _OfflineDocumentsScreenState extends State<OfflineDocumentsScreen> {
  bool _isLoading = true;
  List<OfflineDocumentRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await PdfViewerService.instance.getOfflineDocuments();
    if (!mounted) return;
    setState(() {
      _records = records
        ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
      _isLoading = false;
    });
  }

  Future<void> _deleteRecord(OfflineDocumentRecord record) async {
    final ok = await PdfViewerService.instance.removeOfflineDocument(
      record.storagePath,
    );
    if (!mounted) return;
    if (ok) {
      await _loadRecords();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Offline file removed')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove offline file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openRecord(OfflineDocumentRecord record) {
    context.push(
      '/categories/sub/${record.categoryId}/years/pdf',
      extra: {
        'document': record.toDocumentModel(),
        'categoryColor': AppColors.navyDark,
        'categoryName': record.categoryName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grouped = <String, List<OfflineDocumentRecord>>{};
    for (final record in _records) {
      grouped.putIfAbsent(record.categoryName, () => []).add(record);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offline Files',
              style: AppTextStyles.playfairDisplay.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Downloaded documents available without internet',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadRecords,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : _records.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_done_rounded,
                      size: 64,
                      color: AppColors.charcoal.withValues(alpha: 0.25),
                    ),
                    AppSpacing.vertical(16),
                    Text(
                      'No offline files yet',
                      style: AppTextStyles.playfairDisplay.copyWith(
                        fontSize: 18,
                        color: AppColors.charcoal.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Download a PDF from the year list or viewer to keep it available here.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 12,
                        color: AppColors.charcoal.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: AppColors.gold,
              onRefresh: _loadRecords,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: grouped.length,
                itemBuilder: (context, index) {
                  final categoryName = grouped.keys.elementAt(index);
                  final items = grouped[categoryName]!
                    ..sort((a, b) => b.yearStart.compareTo(a.yearStart));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: AppTextStyles.playfairDisplay.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.charcoal,
                          ),
                        ),
                        AppSpacing.vertical(8),
                        ...items.map(
                          (record) => _OfflineDocCard(
                            record: record,
                            onOpen: () => _openRecord(record),
                            onDelete: () => _deleteRecord(record),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _OfflineDocCard extends StatelessWidget {
  final OfflineDocumentRecord record;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final bool isDark;

  const _OfflineDocCard({
    required this.record,
    required this.onOpen,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        onTap: onOpen,
        leading: const Icon(
          Icons.picture_as_pdf_rounded,
          color: AppColors.gold,
        ),
        title: Text(
          record.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.dmSans.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkText : AppColors.charcoal,
          ),
        ),
        subtitle: Text(
          '${record.yearLabel} · ${record.pageCount ?? 0} pages',
          style: AppTextStyles.dmSans.copyWith(
            fontSize: 12,
            color: AppColors.charcoal.withValues(alpha: 0.55),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'open') onOpen();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(value: 'open', child: Text('Open')),
            PopupMenuItem<String>(value: 'delete', child: Text('Remove')),
          ],
        ),
      ),
    );
  }
}
