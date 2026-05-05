import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:gda_vault_ai/core/constants/supabase_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gda_vault_ai/core/services/supabase_service.dart';
import 'package:gda_vault_ai/models/document_model.dart';

class OfflineDocumentRecord {
  final String storagePath;
  final String localPath;
  final String fileName;
  final String categoryId;
  final String categoryName;
  final String? categorySlug;
  final String yearLabel;
  final int yearStart;
  final int? yearEnd;
  final int? pageCount;
  final int? fileSizeBytes;
  final String? subCategoryId;
  final DateTime downloadedAt;

  const OfflineDocumentRecord({
    required this.storagePath,
    required this.localPath,
    required this.fileName,
    required this.categoryId,
    required this.categoryName,
    required this.yearLabel,
    required this.yearStart,
    this.yearEnd,
    this.categorySlug,
    this.pageCount,
    this.fileSizeBytes,
    this.subCategoryId,
    required this.downloadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'storagePath': storagePath,
      'localPath': localPath,
      'fileName': fileName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categorySlug': categorySlug,
      'yearLabel': yearLabel,
      'yearStart': yearStart,
      'yearEnd': yearEnd,
      'pageCount': pageCount,
      'fileSizeBytes': fileSizeBytes,
      'subCategoryId': subCategoryId,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory OfflineDocumentRecord.fromMap(Map<String, dynamic> map) {
    return OfflineDocumentRecord(
      storagePath: map['storagePath']?.toString() ?? '',
      localPath: map['localPath']?.toString() ?? '',
      fileName: map['fileName']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? '',
      categoryName: map['categoryName']?.toString() ?? '',
      categorySlug: map['categorySlug']?.toString(),
      yearLabel: map['yearLabel']?.toString() ?? '',
      yearStart: int.tryParse(map['yearStart']?.toString() ?? '') ?? 0,
      yearEnd: map['yearEnd'] == null
          ? null
          : int.tryParse(map['yearEnd'].toString()),
      pageCount: map['pageCount'] == null
          ? null
          : int.tryParse(map['pageCount'].toString()),
      fileSizeBytes: map['fileSizeBytes'] == null
          ? null
          : int.tryParse(map['fileSizeBytes'].toString()),
      subCategoryId: map['subCategoryId']?.toString(),
      downloadedAt:
          DateTime.tryParse(map['downloadedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  DocumentModel toDocumentModel() {
    return DocumentModel(
      id: storagePath,
      categoryId: categoryId,
      yearStart: yearStart,
      fileName: fileName,
      storagePath: localPath,
      pageCount: pageCount,
      fileSizeBytes: fileSizeBytes,
      uploadedAt: downloadedAt,
      categoryName: categoryName,
      categorySlug: categorySlug,
      subCategoryId: subCategoryId,
    );
  }
}

class _CategoryMeta {
  final String id;
  final String slug;
  final String name;
  final List<String> pathPrefixes;
  final List<String> aliases;

  const _CategoryMeta({
    required this.id,
    required this.slug,
    required this.name,
    this.pathPrefixes = const [],
    this.aliases = const [],
  });
}

const List<_CategoryMeta> _knownCategories = <_CategoryMeta>[
  _CategoryMeta(
    id: SupabaseConstants.idBoardAuthorityMinutes,
    slug: 'board-authority-minutes',
    name: 'Board Authority Minutes (1996-2026)',
    pathPrefixes: [SupabaseConstants.pathBoardAuthorityMinutes],
    aliases: ['board authority minutes', 'board-authority-minutes'],
  ),
  _CategoryMeta(
    id: SupabaseConstants.idTrustMinutes,
    slug: 'trust-minutes',
    name: 'Trust Minutes Archive (1961-1996)',
    pathPrefixes: [SupabaseConstants.pathTrustMinutes],
    aliases: ['trust minutes', 'trust-minutes', 'trust-minutes-archive'],
  ),
  _CategoryMeta(
    id: SupabaseConstants.idTownPlots,
    slug: 'town-plots',
    name: 'Town (Plot) Files',
    pathPrefixes: [SupabaseConstants.pathTownPlots],
    aliases: ['town plots', 'town-plots-files'],
  ),
  _CategoryMeta(
    id: SupabaseConstants.idAdministration,
    slug: 'administration',
    name: 'Administration',
    pathPrefixes: [SupabaseConstants.pathAdministration],
    aliases: ['administration files', 'administration-files'],
  ),
  _CategoryMeta(
    id: SupabaseConstants.idPrivateProperties,
    slug: 'private-properties',
    name: 'Private Properties',
    pathPrefixes: [SupabaseConstants.pathPrivateProperties],
    aliases: ['private properties', 'private-properties-files'],
  ),
  _CategoryMeta(
    id: SupabaseConstants.idBoardOfAuthority,
    slug: 'board-of-authority',
    name: 'Board of Authority',
    pathPrefixes: ['board-of-authority'],
    aliases: ['board of authority'],
  ),
];

/// Handles fetching PDFs from Supabase Storage and local caching.
class PdfViewerService {
  PdfViewerService._();
  static final PdfViewerService instance = PdfViewerService._();

  final Map<String, String> _cache = {};
  List<DocumentModel>? _recentlyOpened;
  File? _recentIndexCacheFile;
  List<OfflineDocumentRecord>? _offlineRecords;
  File? _indexFile;

  Future<File> get _recentIndexFile async {
    if (_recentIndexCacheFile != null) return _recentIndexCacheFile!;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/offline_cache');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    _recentIndexCacheFile = File('${folder.path}/recent_opened.json');
    return _recentIndexCacheFile!;
  }

  Future<List<DocumentModel>> _loadRecentOpened() async {
    if (_recentlyOpened != null) return _recentlyOpened!;
    try {
      final file = await _recentIndexFile;
      if (!await file.exists()) {
        _recentlyOpened = <DocumentModel>[];
        return _recentlyOpened!;
      }
      final text = await file.readAsString();
      final decoded = jsonDecode(text);
      if (decoded is! List) {
        _recentlyOpened = <DocumentModel>[];
        return _recentlyOpened!;
      }
      _recentlyOpened = decoded
          .whereType<Map>()
          .map(
            (entry) => DocumentModel.fromMap(Map<String, dynamic>.from(entry)),
          )
          .toList();
      return _recentlyOpened!;
    } catch (e) {
      debugPrint('load recent opened error: $e');
      _recentlyOpened = <DocumentModel>[];
      return _recentlyOpened!;
    }
  }

  Future<void> _saveRecentOpened(List<DocumentModel> docs) async {
    _recentlyOpened = docs;
    final file = await _recentIndexFile;
    await file.writeAsString(
      jsonEncode(docs.map((doc) => doc.toMap()).toList()),
    );
  }

  Future<File> get _offlineIndexFile async {
    if (_indexFile != null) return _indexFile!;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/offline_cache');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    _indexFile = File('${folder.path}/index.json');
    return _indexFile!;
  }

  Future<List<OfflineDocumentRecord>> _loadRecords() async {
    if (_offlineRecords != null) return _offlineRecords!;
    try {
      final file = await _offlineIndexFile;
      if (!await file.exists()) {
        _offlineRecords = <OfflineDocumentRecord>[];
        return _offlineRecords!;
      }
      final text = await file.readAsString();
      debugPrint('PdfViewerService: Loaded raw index: $text');
      final decoded = jsonDecode(text);
      if (decoded is! List) {
        _offlineRecords = <OfflineDocumentRecord>[];
        return _offlineRecords!;
      }
      final loaded = decoded
          .whereType<Map>()
          .map(
            (entry) =>
                OfflineDocumentRecord.fromMap(Map<String, dynamic>.from(entry)),
          )
          .toList();

      var changed = false;
      final normalized = loaded.map((record) {
        final known = _resolveKnownCategory(
          categoryId: record.categoryId,
          categorySlug: record.categorySlug,
          categoryName: record.categoryName,
          storagePath: record.storagePath,
        );

        final nextSlug = known?.slug ?? record.categorySlug;
        final nextName =
            (record.categoryName.isNotEmpty &&
                !_looksLikeUuid(record.categoryName))
            ? record.categoryName
            : (known?.name ?? record.categoryName);
        final nextCategoryId = known?.id ?? record.categoryId;

        if (nextSlug != record.categorySlug ||
            nextName != record.categoryName ||
            nextCategoryId != record.categoryId) {
          changed = true;
          return OfflineDocumentRecord(
            storagePath: record.storagePath,
            localPath: record.localPath,
            fileName: record.fileName,
            categoryId: nextCategoryId,
            categoryName: nextName,
            categorySlug: nextSlug,
            subCategoryId: record.subCategoryId,
            yearLabel: record.yearLabel,
            yearStart: record.yearStart,
            yearEnd: record.yearEnd,
            pageCount: record.pageCount,
            fileSizeBytes: record.fileSizeBytes,
            downloadedAt: record.downloadedAt,
          );
        }
        return record;
      }).toList();

      _offlineRecords = normalized;
      if (changed) {
        await _saveRecords(normalized);
      }
      return _offlineRecords!;
    } catch (e) {
      debugPrint('load offline cache error: $e');
      _offlineRecords = <OfflineDocumentRecord>[];
      return _offlineRecords!;
    }
  }

  Future<void> _saveRecords(List<OfflineDocumentRecord> records) async {
    _offlineRecords = records;
    final file = await _offlineIndexFile;
    await file.writeAsString(
      jsonEncode(records.map((record) => record.toMap()).toList()),
    );
  }

  String _normalizeCategoryKey(String value) {
    return value.trim().toLowerCase().replaceAll('_', '-').replaceAll(' ', '-');
  }

  bool _looksLikeUuid(String value) {
    final v = value.trim();
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(v);
  }

  _CategoryMeta? _matchKnownCategory(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) return null;
    final normalized = _normalizeCategoryKey(rawValue);
    for (final category in _knownCategories) {
      if (category.id == rawValue) return category;
      if (category.slug == normalized) return category;
      if (category.aliases.any(
        (alias) => _normalizeCategoryKey(alias) == normalized,
      )) {
        return category;
      }
    }
    return null;
  }

  _CategoryMeta? _matchByStoragePath(String? storagePath) {
    if (storagePath == null || storagePath.trim().isEmpty) return null;
    final normalizedPath = storagePath
        .trim()
        .replaceAll('\\', '/')
        .toLowerCase();
    for (final category in _knownCategories) {
      for (final prefix in category.pathPrefixes) {
        final normalizedPrefix = prefix.toLowerCase();
        if (normalizedPath.startsWith(normalizedPrefix)) {
          return category;
        }
      }
    }
    return null;
  }

  _CategoryMeta? _resolveKnownCategory({
    String? categoryId,
    String? categorySlug,
    String? categoryName,
    String? storagePath,
  }) {
    return _matchKnownCategory(categoryId) ??
        _matchKnownCategory(categorySlug) ??
        _matchKnownCategory(categoryName) ??
        _matchByStoragePath(storagePath);
  }

  String _safeSegment(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(' ', '_');
  }

  Future<Directory> _offlineDirectoryFor(DocumentModel document) async {
    final root = await getApplicationDocumentsDirectory();
    final known = _resolveKnownCategory(
      categoryId: document.categoryId,
      categorySlug: document.categorySlug,
      categoryName: document.categoryName,
      storagePath: document.storagePath,
    );
    final categorySegment = _safeSegment(
      known?.slug ?? document.categorySlug ?? document.categoryId,
    );
    final yearSegment = _safeSegment(
      document.yearLabel.isEmpty ? '${document.yearStart}' : document.yearLabel,
    );
    final directory = Directory(
      '${root.path}/offline_cache/$categorySegment/$yearSegment',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<OfflineDocumentRecord?> _findRecord(String storagePath) async {
    final records = await _loadRecords();
    for (final record in records) {
      if (record.storagePath == storagePath) return record;
    }
    return null;
  }

  Future<File?> getLocalPdfPath(String storagePath, String fileName) async {
    final record = await _findRecord(storagePath);
    if (record != null) {
      final file = File(record.localPath);
      if (await file.exists()) return file;
    }

    final cachedPath = _cache[storagePath];
    if (cachedPath != null) {
      final file = File(cachedPath);
      if (await file.exists()) return file;
      _cache.remove(storagePath);
    }

    try {
      final dir = await getTemporaryDirectory();
      final safeFileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final localFile = File('${dir.path}/$safeFileName');
      if (await localFile.exists()) {
        _cache[storagePath] = localFile.path;
        return localFile;
      }
    } catch (e) {
      debugPrint('getLocalPdfPath error: $e');
    }

    return null;
  }

  Future<void> recordRecentlyOpened(DocumentModel document) async {
    try {
      final records = await _loadRecentOpened();
      final updated = [
        document,
        ...records.where((item) => item.storagePath != document.storagePath),
      ].take(12).toList();
      await _saveRecentOpened(updated);
    } catch (e) {
      debugPrint('recordRecentlyOpened error: $e');
    }
  }

  Future<List<DocumentModel>> getRecentlyOpenedDocuments() async {
    return _loadRecentOpened();
  }

  Future<File?> downloadDocument(
    DocumentModel document, {
    void Function(double progress, String status)? onProgress,
  }) async {
    final existing = await getLocalPdfPath(
      document.storagePath,
      document.fileName,
    );
    if (existing != null && await existing.exists()) {
      return existing;
    }

    try {
      onProgress?.call(0.05, 'Preparing download...');
      final signedUrl = await SupabaseService.instance.getSignedUrl(
        document.storagePath,
      );
      if (signedUrl == null || signedUrl.isEmpty) {
        throw StateError('Could not create signed URL');
      }

      final directory = await _offlineDirectoryFor(document);
      final safeName = _safeSegment(
        document.fileName.endsWith('.pdf')
            ? document.fileName
            : '${document.fileName}.pdf',
      );
      final localFile = File('${directory.path}/$safeName');
      final tempFile = File('${localFile.path}.part');

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(signedUrl));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Download failed with status ${response.statusCode}',
        );
      }

      final contentLength = response.contentLength;
      var received = 0;
      final sink = tempFile.openWrite();
      await for (final chunk in response) {
        received += chunk.length;
        sink.add(chunk);
        if (contentLength > 0) {
          final progress = min(received / contentLength, 0.98);
          onProgress?.call(
            progress,
            'Downloading ${(progress * 100).toStringAsFixed(0)}%',
          );
        }
      }
      await sink.flush();
      await sink.close();
      client.close(force: true);

      if (await localFile.exists()) {
        await localFile.delete();
      }
      await tempFile.rename(localFile.path);

      final records = await _loadRecords();
      final known = _resolveKnownCategory(
        categoryId: document.categoryId,
        categorySlug: document.categorySlug,
        categoryName: document.categoryName,
        storagePath: document.storagePath,
      );
      final resolvedCategoryName =
          (document.categoryName != null &&
              document.categoryName!.isNotEmpty &&
              !_looksLikeUuid(document.categoryName!))
          ? document.categoryName!
          : (known?.name ?? document.categorySlug ?? document.categoryId);
      final record = OfflineDocumentRecord(
        storagePath: document.storagePath,
        localPath: localFile.path,
        fileName: document.fileName,
        categoryId: known?.id ?? document.categoryId,
        subCategoryId: document.subCategoryId,
        categoryName: resolvedCategoryName,
        categorySlug: known?.slug ?? document.categorySlug,
        yearLabel: document.yearLabel,
        yearStart: document.yearStart,
        pageCount: document.pageCount,
        fileSizeBytes: document.fileSizeBytes,
        downloadedAt: DateTime.now(),
      );

      final nextRecords = [
        record,
        ...records.where((item) => item.storagePath != document.storagePath),
      ];
      await _saveRecords(nextRecords);
      _cache[document.storagePath] = localFile.path;
      onProgress?.call(1.0, 'Download complete');
      return localFile;
    } catch (e) {
      debugPrint('downloadDocument error: $e');
      return null;
    }
  }

  Future<List<OfflineDocumentRecord>> getOfflineDocuments() async {
    final records = await _loadRecords();
    final verified = <OfflineDocumentRecord>[];
    for (final r in records) {
      if (await File(r.localPath).exists()) {
        verified.add(r);
      }
    }
    if (verified.length != records.length) {
      await _saveRecords(verified);
    }
    debugPrint('PdfViewerService: Found ${records.length} total records, ${verified.length} verified');
    return verified;
  }

  Future<bool> removeOfflineDocument(String storagePath) async {
    try {
      final records = await _loadRecords();
      final record = records
          .where((item) => item.storagePath == storagePath)
          .toList();
      if (record.isNotEmpty) {
        final localFile = File(record.first.localPath);
        if (await localFile.exists()) {
          await localFile.delete();
        }
      }
      await _saveRecords(
        records.where((item) => item.storagePath != storagePath).toList(),
      );
      _cache.remove(storagePath);
      return true;
    } catch (e) {
      debugPrint('removeOfflineDocument error: $e');
      return false;
    }
  }

  /// Get signed URL for network PDF viewer.
  /// Signed URLs should NOT be cached (they expire).
  Future<String?> getSignedUrl(String storagePath) async {
    return SupabaseService.instance.getSignedUrl(storagePath);
  }

  /// Clear in-memory cache.
  void clearCache() {
    _cache.clear();
    _offlineRecords = null;
  }
}
