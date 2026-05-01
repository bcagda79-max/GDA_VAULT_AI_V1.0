import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/constants/supabase_constants.dart';
import 'package:gda_vault_ai/core/services/pdf_viewer_service.dart';

class OfflineDocumentsScreen extends StatefulWidget {
  const OfflineDocumentsScreen({super.key});

  @override
  State<OfflineDocumentsScreen> createState() => _OfflineDocumentsScreenState();
}

class _OfflineDocumentsScreenState extends State<OfflineDocumentsScreen> {
  static const List<_OfflineFolderMeta> _folders = [
    _OfflineFolderMeta(
      key: 'board-authority',
      title: 'Board of Authority',
      fallbackRange: '1961 – Ongoing',
      color: AppColors.catBoard,
      icon: Icons.gavel_rounded,
      routeType: _OfflineFolderRouteType.boardSubcategories,
      aliases: [
        'board-authority-minutes',
        'board authority minutes',
        'board-of-authority',
      ],
    ),
    _OfflineFolderMeta(
      key: 'town-plots',
      title: 'Town (Plots) Files',
      fallbackRange: '1999 – 2026',
      color: AppColors.catTown,
      icon: Icons.location_city_rounded,
      routeType: _OfflineFolderRouteType.yearBrowser,
      categoryId: SupabaseConstants.idTownPlots,
      categoryName: 'Town (Plots) Files',
      yearFrom: 1999,
      yearTo: 2026,
      aliases: [
        'town-plots',
        'town-plots-files',
        'town plots',
        SupabaseConstants.idTownPlots,
      ],
    ),
    _OfflineFolderMeta(
      key: 'administration',
      title: 'Administration Files',
      fallbackRange: '1999 – 2026',
      color: AppColors.catAdmin,
      icon: Icons.admin_panel_settings_rounded,
      routeType: _OfflineFolderRouteType.yearBrowser,
      categoryId: SupabaseConstants.idAdministration,
      categoryName: 'Administration Files',
      yearFrom: 1999,
      yearTo: 2026,
      aliases: [
        'administration',
        'administration-files',
        'administration files',
        SupabaseConstants.idAdministration,
      ],
    ),
    _OfflineFolderMeta(
      key: 'private-properties',
      title: 'Private Properties Files',
      fallbackRange: '1999 – 2026',
      color: AppColors.catPrivate,
      icon: Icons.home_work_rounded,
      routeType: _OfflineFolderRouteType.yearBrowser,
      categoryId: SupabaseConstants.idPrivateProperties,
      categoryName: 'Private Properties Files',
      yearFrom: 1999,
      yearTo: 2026,
      aliases: [
        'private-properties',
        'private-properties-files',
        'private properties',
        SupabaseConstants.idPrivateProperties,
      ],
    ),
  ];

  bool _isLoading = true;
  List<OfflineDocumentRecord> _records = const [];
  Map<String, int> _counts = const {};

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll('_', '-').replaceAll(' ', '-');
  }

  String _storagePrefix(String path) {
    final normalized = path.replaceAll('\\', '/').trim();
    final slash = normalized.indexOf('/');
    if (slash <= 0) return normalized;
    return normalized.substring(0, slash);
  }

  String _mainFolderKeyFor(OfflineDocumentRecord record) {
    final candidates = <String?>[
      record.categorySlug,
      record.categoryId,
      record.categoryName,
      _storagePrefix(record.storagePath),
    ];

    for (final candidate in candidates) {
      if (candidate == null || candidate.trim().isEmpty) continue;
      final normalized = _normalize(candidate);
      for (final folder in _folders) {
        if (folder.key == normalized) return folder.key;
        if (folder.aliases.any((alias) => _normalize(alias) == normalized)) {
          return folder.key;
        }
      }
      if (normalized.contains('board') || normalized.contains('trust')) {
        return 'board-authority';
      }
    }

    return 'unclassified';
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await PdfViewerService.instance.getOfflineDocuments();
    if (!mounted) return;

    final counts = <String, int>{for (final folder in _folders) folder.key: 0};

    for (final record in records) {
      final key = _mainFolderKeyFor(record);
      if (counts.containsKey(key)) {
        counts[key] = counts[key]! + 1;
      }
    }

    setState(() {
      _records = records;
      _counts = counts;
      _isLoading = false;
    });
  }

  String _rangeLabelFor(_OfflineFolderMeta folder) {
    final folderRecords = _records
        .where((record) => _mainFolderKeyFor(record) == folder.key)
        .toList();
    if (folderRecords.isEmpty) return folder.fallbackRange;

    final years =
        folderRecords
            .map((record) => record.yearStart)
            .where((year) => year > 0)
            .toList()
          ..sort();

    final minYear = years.isEmpty ? folder.yearFrom : years.first;
    final maxYear = years.isEmpty ? folder.yearTo : years.last;
    final hasOngoing = folderRecords.any((record) => record.yearEnd == null);

    if (folder.key == 'board-authority' && hasOngoing && minYear != null) {
      return '$minYear – Ongoing';
    }
    if (minYear == null) return folder.fallbackRange;
    if (maxYear == null || minYear == maxYear) return '$minYear';
    return '$minYear – $maxYear';
  }

  void _openFolder(_OfflineFolderMeta folder) {
    switch (folder.routeType) {
      case _OfflineFolderRouteType.boardSubcategories:
        context.push(
          '/categories/sub/${SupabaseConstants.idBoardOfAuthority}',
          extra: {'categoryName': 'Board of Authority'},
        );
        return;
      case _OfflineFolderRouteType.yearBrowser:
        context.push(
          '/categories/sub/${folder.categoryId}/years',
          extra: {
            'categoryName': folder.categoryName,
            'categoryColor': folder.color,
            'yearFrom': folder.yearFrom ?? 1999,
            'yearTo': folder.yearTo,
            'subCategoryName': null,
          },
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        automaticallyImplyLeading: false,
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
              'Choose a folder',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : RefreshIndicator(
              color: AppColors.gold,
              onRefresh: _loadRecords,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  ..._folders.where((folder) => (_counts[folder.key] ?? 0) > 0).map((
                    folder,
                  ) {
                    final count = _counts[folder.key] ?? 0;
                    final range = _rangeLabelFor(folder);
                    final isBoard = folder.key == 'board-authority';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openFolder(folder),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  folder.color.withValues(alpha: 0.9),
                                  folder.color.withValues(alpha: 0.68),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    folder.icon,
                                    color: AppColors.gdaGold,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              folder.title,
                                              style: AppTextStyles
                                                  .playfairDisplay
                                                  .copyWith(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isBoard)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.14,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '2 sub',
                                                style: AppTextStyles.dmSans
                                                    .copyWith(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        range,
                                        style: AppTextStyles.dmSans.copyWith(
                                          fontSize: 11,
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '$count file${count == 1 ? '' : 's'}',
                                              style: AppTextStyles.dmSans
                                                  .copyWith(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_folders
                      .where((folder) => (_counts[folder.key] ?? 0) > 0)
                      .isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 56),
                      child: Center(
                        child: Text(
                          'No offline files yet',
                          style: AppTextStyles.playfairDisplay.copyWith(
                            fontSize: 18,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.charcoal,
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

enum _OfflineFolderRouteType { boardSubcategories, yearBrowser }

class _OfflineFolderMeta {
  final String key;
  final String title;
  final String fallbackRange;
  final Color color;
  final IconData icon;
  final _OfflineFolderRouteType routeType;
  final String? categoryId;
  final String? categoryName;
  final int? yearFrom;
  final int? yearTo;
  final List<String> aliases;

  const _OfflineFolderMeta({
    required this.key,
    required this.title,
    required this.fallbackRange,
    required this.color,
    required this.icon,
    required this.routeType,
    this.categoryId,
    this.categoryName,
    this.yearFrom,
    this.yearTo,
    this.aliases = const [],
  });
}
