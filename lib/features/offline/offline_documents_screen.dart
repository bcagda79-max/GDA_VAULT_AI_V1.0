import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/constants/supabase_constants.dart';
import 'package:gda_vault_ai/core/services/pdf_viewer_service.dart';
import 'package:gda_vault_ai/core/utils/responsive_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gda_vault_ai/features/offline/offline_browser_screen.dart';

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
      categoryId: SupabaseConstants.idBoardOfAuthority,
      aliases: [
        'board-authority-minutes',
        'board authority minutes',
        'board-of-authority',
        SupabaseConstants.idBoardOfAuthority,
      ],
    ),
    _OfflineFolderMeta(
      key: 'town-plots',
      title: 'Town (Plots) Files',
      fallbackRange: '1999 – 2026',
      color: AppColors.catBoard,
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
      color: AppColors.catBoard,
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
      color: AppColors.catBoard,
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
    _OfflineFolderMeta(
      key: 'unclassified',
      title: 'Other Documents',
      fallbackRange: 'Misc',
      color: Colors.grey,
      icon: Icons.folder_open_rounded,
      routeType: _OfflineFolderRouteType.yearBrowser,
      aliases: ['unclassified', 'other'],
    ),
  ];

  final _pdfService = PdfViewerService.instance;
  bool _isLoading = true;
  List<OfflineDocumentRecord> _records = const [];
  Map<String, int> _counts = const {};
  Map<String, bool> _hasSubCategories = {};

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
        if (folder.categoryId == candidate) return folder.key;
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
    final all = await _pdfService.getOfflineDocuments();
    debugPrint('OfflineDocumentsScreen: Loaded ${all.length} records');

    final counts = <String, int>{};
    final catSubPresence = <String, Set<String>>{};

    for (final r in all) {
      final key = _mainFolderKeyFor(r);
      counts[key] = (counts[key] ?? 0) + 1;

      // Track subcategories for each main folder
      if (r.subCategoryId != null && r.subCategoryId!.isNotEmpty) {
        catSubPresence.putIfAbsent(key, () => {}).add(r.subCategoryId!);
      } else {
        final folder = _folders.firstWhere(
          (f) => f.key == key,
          orElse: () => _folders.first,
        );
        if (r.categoryName.isNotEmpty && r.categoryName != folder.title) {
          catSubPresence.putIfAbsent(key, () => {}).add(r.categoryName);
        }
      }
    }

    if (mounted) {
      setState(() {
        _records = all;
        _counts = counts;
        _hasSubCategories = catSubPresence.map(
          (key, subs) => MapEntry(key, subs.isNotEmpty),
        );
        _isLoading = false;
      });
    }
  }

  void _navigateToFolder(BuildContext context, _OfflineFolderMeta folder) {
    final hasSubs = _hasSubCategories[folder.key] ?? false;

    if (hasSubs) {
      context.push(
        '/dashboard/offline-documents/sub/${folder.categoryId}',
        extra: {
          'categoryName': folder.title,
          'categoryColor': folder.color,
          'viewType': OfflineBrowserViewType.subcategories,
        },
      );
    } else {
      context.push(
        '/dashboard/offline-documents/sub/${folder.categoryId}',
        extra: {
          'categoryName': folder.title,
          'categoryColor': folder.color,
          'viewType': OfflineBrowserViewType.years,
        },
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeFolders = _folders
        .where((f) => (_counts[f.key] ?? 0) > 0)
        .toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
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
                    const SizedBox(width: 40),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Offline Files',
                              style: AppTextStyles.playfairDisplay.copyWith(
                                fontSize: ResponsiveAppBar.isDesktop(context)
                                    ? 20
                                    : 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Locally cached documents',
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: ResponsiveAppBar.isDesktop(context)
                                    ? 10
                                    : 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.5),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
          // Background Glows (matching Categories screen)
          Positioned(
            top: -60,
            left: -50,
            child: IgnorePointer(
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: isDark ? 0.16 : 0.09),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 240,
            right: -70,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.navyLight.withValues(
                        alpha: isDark ? 0.12 : 0.06,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    : activeFolders.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        color: AppColors.gold,
                        onRefresh: _loadRecords,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                          children: [
                            _buildSectionHeader(
                              context,
                              isDark,
                              activeFolders.length,
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(activeFolders.length, (index) {
                              final folder = activeFolders[index];
                              return _buildFolderItem(
                                context,
                                folder,
                                index,
                                isDark,
                                count: _counts[folder.key] ?? 0,
                              );
                            }),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, bool isDark, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FOLDERS',
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: (isDark ? AppColors.darkText : AppColors.charcoal)
                      .withValues(alpha: 0.5),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap any category to open its documents',
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 12,
                  color: (isDark ? AppColors.darkText : AppColors.charcoal)
                      .withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.gold.withValues(alpha: 0.15)
                  : AppColors.navyDark.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppColors.gold.withValues(alpha: 0.3)
                    : AppColors.navyDark.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 12,
                  color: isDark ? AppColors.gold : AppColors.navyDark,
                ),
                const SizedBox(width: 5),
                Text(
                  '$count found',
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.gold : AppColors.navyDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(
    BuildContext context,
    _OfflineFolderMeta folder,
    int index,
    bool isDark, {
    required int count,
  }) {
    final range = _rangeLabelFor(folder);
    final isBoard = folder.key == 'board-authority';

    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppColors.darkCard, folder.color.withValues(alpha: 0.35)]
                  : [folder.color, folder.color.withValues(alpha: 0.85)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? folder.color.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : folder.color.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              splashColor: Colors.white.withValues(alpha: 0.08),
              onTap: () => _navigateToFolder(context, folder),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(folder.icon, size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  folder.title,
                                  style: AppTextStyles.playfairDisplay.copyWith(
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
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '2 sub',
                                    style: AppTextStyles.dmSans.copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.date_range_rounded,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.68),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                range,
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                              Container(
                                width: 3,
                                height: 3,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                '$count files',
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: (count / 50.0).clamp(0.0, 1.0),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.14,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.gdaGold,
                              ),
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: index * 70))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.03, end: 0, duration: 300.ms);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCard
                  : AppColors.navyDark.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.gold.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No offline files yet',
            style: AppTextStyles.playfairDisplay.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Documents you save for offline access\nwill appear here for instant viewing.',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 13,
              color: (isDark ? Colors.white : AppColors.charcoal).withValues(
                alpha: 0.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9));
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
