import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gda_vault_ai/core/constants/supabase_constants.dart';

/// Singleton Supabase service — all DB + Storage operations.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  List<Map<String, dynamic>>? _categoryCache;

  // ── Storage bucket name ──
  static const String _bucket = SupabaseConstants.bucketName;

  // ══════════════════════════════════════════════
  // CATEGORY OPERATIONS
  // ══════════════════════════════════════════════

  /// Get all categories with aggregated document count/stats.
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final response = await client
          .from('category_stats')
          .select()
          .order('sort_order', ascending: true);
      final categories = List<Map<String, dynamic>>.from(response);
      _categoryCache = categories;
      return categories;
    } catch (e) {
      debugPrint('getAllCategories error: $e');
      return [];
    }
  }

  /// Resolve a category key that may be either a UUID id or a slug.
  Future<String?> resolveCategoryId(String categoryKey) async {
    final cached = _categoryCache;
    if (cached != null) {
      final match = cached.firstWhere(
        (row) =>
            row['id']?.toString() == categoryKey ||
            row['slug']?.toString() == categoryKey,
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) return match['id']?.toString();
    }

    final rows = await getAllCategories();
    for (final row in rows) {
      final id = row['id']?.toString();
      final slug = row['slug']?.toString();
      if (id == categoryKey || slug == categoryKey) return id;
    }
    return null;
  }

  /// Get sub-categories by parent id.
  Future<List<Map<String, dynamic>>> getSubCategories(String parentId) async {
    try {
      final response = await client
          .from('category_stats')
          .select()
          .eq('parent_id', parentId)
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getSubCategories error: $e');
      return [];
    }
  }

  /// Get top-level categories (no parent).
  Future<List<Map<String, dynamic>>> getTopLevelCategories() async {
    try {
      final response = await client
          .from('category_stats')
          .select()
          .isFilter('parent_id', null)
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getTopLevelCategories error: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════
  // DOCUMENT OPERATIONS
  // ══════════════════════════════════════════════

  /// Get all documents for a category.
  Future<List<Map<String, dynamic>>> getDocumentsByCategory(
    String categoryKey,
  ) async {
    try {
      final categoryId = await resolveCategoryId(categoryKey);
      if (categoryId == null || categoryId.isEmpty) {
        debugPrint('getDocumentsByCategory: unknown category key $categoryKey');
        return [];
      }
      final response = await client
          .from('documents')
          .select()
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('year_start', ascending: true)
          .order('uploaded_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getDocumentsByCategory error: $e');
      return [];
    }
  }

  /// Get documents for a category + specific year.
  Future<List<Map<String, dynamic>>> getDocumentsByYear(
    String categoryKey,
    int year,
  ) async {
    try {
      final categoryId = await resolveCategoryId(categoryKey);
      if (categoryId == null || categoryId.isEmpty) {
        debugPrint('getDocumentsByYear: unknown category key $categoryKey');
        return [];
      }
      final response = await client
          .from('documents')
          .select()
          .eq('category_id', categoryId)
          .eq('year_start', year)
          .eq('is_active', true)
          .order('uploaded_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getDocumentsByYear error: $e');
      return [];
    }
  }

  /// Get distinct years available for a category.
  Future<List<int>> getAvailableYears(String categoryId) async {
    try {
      final resolvedCategoryId = await resolveCategoryId(categoryId);
      if (resolvedCategoryId == null || resolvedCategoryId.isEmpty) {
        return [];
      }
      final response = await client
          .from('documents')
          .select('year_start')
          .eq('category_id', resolvedCategoryId)
          .eq('is_active', true)
          .order('year_start', ascending: false);

      final years =
          (response as List)
              .map<int>((row) {
                final value = (row as Map<String, dynamic>)['year_start'];
                if (value is int) return value;
                if (value is num) return value.toInt();
                return int.tryParse(value.toString()) ?? 0;
              })
              .where((y) => y > 0)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

      return years;
    } catch (e) {
      debugPrint('getAvailableYears error: $e');
      return [];
    }
  }

  /// Insert document record after upload.
  Future<Map<String, dynamic>?> insertDocument({
    required String categoryId,
    required String yearLabel,
    required int yearStart,
    int? yearEnd,
    required String fileName,
    required String storagePath,
    int? fileSizeBytes,
    int? pageCount,
  }) async {
    try {
      final response = await client
          .from('documents')
          .insert({
            'category_id': categoryId,
            'year_label': yearLabel,
            'year_start': yearStart,
            'year_end': yearEnd,
            'file_name': fileName,
            'storage_path': storagePath,
            'file_size_bytes': fileSizeBytes,
            'page_count': pageCount,
            'mime_type': 'application/pdf',
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('insertDocument error: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════
  // STORAGE OPERATIONS
  // ══════════════════════════════════════════════

  /// Build storage path from category + year + filename.
  /// Pattern: `{category_storage_path}/{year}/{timestamp}_{filename}`
  String buildStoragePath({
    required String categoryStoragePath,
    required String year,
    required String fileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '');
    return '$categoryStoragePath/$year/${timestamp}_$safeName';
  }

  /// Upload PDF file to Supabase Storage.
  Future<String?> uploadPdf({
    required File file,
    required String storagePath,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      await client.storage
          .from(_bucket)
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: false,
            ),
          );

      debugPrint('Upload success: $storagePath');
      return storagePath;
    } on StorageException catch (e) {
      debugPrint('Storage upload error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  /// Upload PDF from bytes (for scanned documents).
  Future<String?> uploadPdfBytes({
    required List<int> bytes,
    required String storagePath,
  }) async {
    try {
      await client.storage
          .from(_bucket)
          .uploadBinary(
            storagePath,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: false,
            ),
          );
      return storagePath;
    } on StorageException catch (e) {
      debugPrint('Storage bytes upload error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Upload bytes error: $e');
      return null;
    }
  }

  /// Get signed URL for viewing PDF (valid 2 hours).
  Future<String?> getSignedUrl(String storagePath) async {
    try {
      final signedUrl = await client.storage
          .from(_bucket)
          .createSignedUrl(storagePath, 7200);
      return signedUrl;
    } catch (e) {
      debugPrint('getSignedUrl error: $e');
      return null;
    }
  }

  /// Download PDF to local temp directory.
  Future<File?> downloadPdf(String storagePath, String localFileName) async {
    try {
      final bytes = await client.storage.from(_bucket).download(storagePath);

      final tempDir = await getTemporaryDirectory();
      final safeFileName = localFileName.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );
      final localFile = File('${tempDir.path}/$safeFileName');
      await localFile.writeAsBytes(bytes);
      return localFile;
    } catch (e) {
      debugPrint('downloadPdf error: $e');
      return null;
    }
  }

  /// List all files in a storage path/folder.
  Future<List<FileObject>> listFilesInPath(String path) async {
    try {
      final response = await client.storage.from(_bucket).list(path: path);
      return response;
    } catch (e) {
      debugPrint('listFiles error: $e');
      return [];
    }
  }

  /// Delete a file from storage.
  Future<bool> deleteFile(String storagePath) async {
    try {
      await client.storage.from(_bucket).remove([storagePath]);
      return true;
    } catch (e) {
      debugPrint('deleteFile error: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════
  // DASHBOARD STATS
  // ══════════════════════════════════════════════

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await client.rpc('get_dashboard_stats');

      if (response is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response);
      }
      if (response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response.first as Map);
      }

      return {
        'total_documents': 0,
        'total_pages': 0,
        'total_size_gb': 0.0,
        'category_count': 5,
      };
    } catch (e) {
      debugPrint('getDashboardStats error: $e');
      return {
        'total_documents': 0,
        'total_pages': 0,
        'total_size_gb': 0.0,
        'category_count': 5,
      };
    }
  }

  /// Recent documents (last 10 uploads).
  Future<List<Map<String, dynamic>>> getRecentDocuments() async {
    try {
      final response = await client
          .from('documents')
          .select('''
            id, category_id, file_name, storage_path, year_label, year_start,
            year_end, page_count, file_size_bytes, uploaded_at,
            categories!inner(name, color_hex, slug)
          ''')
          .eq('is_active', true)
          .order('uploaded_at', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getRecentDocuments error: $e');
      return [];
    }
  }
}
