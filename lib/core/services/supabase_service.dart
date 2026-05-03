import 'dart:io';
import 'dart:async';
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

  /// Get a single document by its storage path.
  Future<Map<String, dynamic>?> getDocumentByPath(String path) async {
    try {
      final response = await client
          .from('documents')
          .select('*, categories(*)')
          .eq('storage_path', path)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('getDocumentByPath error: $e');
      return null;
    }
  }

  /// Find a document by its metadata (Category, Year, FileName).
  /// Used for deep-linking from AI citations when direct path is unreliable.
  Future<Map<String, dynamic>?> findDocumentByMetadata({
    required String categoryName,
    required String fileName,
    required String year,
    String? subCategoryName,
  }) async {
    try {
      final parsedYear = int.tryParse(year);
      final cleanFileName = fileName.trim();
      final cleanCategoryName = categoryName.trim();

      // Use the correct relationship hint '!category' which is used elsewhere in the service
      var query = client
          .from('documents')
          .select('*, categories!category!inner(*)');

      // 1. Filter by filename (using ilike for partial matching)
      query = query.ilike('file_name', '%$cleanFileName%');

      // 2. Filter by year only if it's a valid year (> 1900)
      if (parsedYear != null && parsedYear > 1900) {
        query = query.eq('year', parsedYear);
      }

      // 3. Filter by category name
      query = query.ilike('categories.name', '%$cleanCategoryName%');

      final results = await query;

      if (results.isNotEmpty) {
        // If multiple, try to find the best match for sub-category if provided
        if (subCategoryName != null && subCategoryName.isNotEmpty) {
          // We can do a manual filter or add to query if needed,
          // but usually the filename + year + category is unique enough.
        }
        return results.first;
      }

      // Secondary fallback: if year was provided and failed, try WITHOUT the year filter
      if (parsedYear != null && parsedYear > 1900 && results.isEmpty) {
        var fallbackQuery = client
            .from('documents')
            .select('*, categories!category!inner(*)')
            .ilike('file_name', '%$cleanFileName%')
            .ilike('categories.name', '%$cleanCategoryName%');

        final fallbackResults = await fallbackQuery;
        if (fallbackResults.isNotEmpty) return fallbackResults.first;
      }

      // Third fallback: Last resort - search by filename alone (if filename is specific enough)
      if (results.isEmpty && cleanFileName.length > 4) {
        var lastResortQuery = client
            .from('documents')
            .select('*, categories!category!inner(*)')
            .ilike('file_name', '%$cleanFileName%')
            .limit(1);

        final lastResortResults = await lastResortQuery;
        if (lastResortResults.isNotEmpty) return lastResortResults.first;
      }

      return null;
    } catch (e) {
      debugPrint('findDocumentByMetadata error: $e');
      return null;
    }
  }

  /// Get documents for a category or sub-category.
  Future<List<Map<String, dynamic>>> getDocumentsByCategory(
    String categoryKey, {
    String? subCategoryId,
  }) async {
    try {
      final categoryId = await resolveCategoryId(categoryKey);
      if (categoryId == null || categoryId.isEmpty) {
        debugPrint('getDocumentsByCategory: unknown category key $categoryKey');
        return [];
      }

      // Reverting to a more permissive query to ensure documents ALWAYS show up.
      // We will handle specific sub-category filtering in the UI/Dart logic if needed.
      final response = await client
          .from('documents')
          .select('*, categories!category(id, name, slug, color_hex)')
          .or('category.eq.$categoryId,sub_category.eq.$categoryId')
          .order('year', ascending: true)
          .order('uploaded_at', ascending: false);

      debugPrint(
        'getDocumentsByCategory: found ${response.length} rows for $categoryId',
      );

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
          .select('*, categories!category(id, name, slug, color_hex)')
          .or('category.eq.$categoryId,sub_category.eq.$categoryId')
          .eq('year', year)
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
          .select('year')
          .or(
            'category.eq.$resolvedCategoryId,sub_category.eq.$resolvedCategoryId',
          )
          .order('year', ascending: false);

      final years =
          (response as List)
              .map<int>((row) {
                final value = (row as Map<String, dynamic>)['year'];
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
    required String category,
    String? subCategory,
    required int year,
    required String fileName,
    required String storagePath,
    int? fileSizeBytes,
    int? pageCount,
  }) async {
    try {
      final response = await client
          .from('documents')
          .insert({
            'category': category,
            'sub_category': subCategory,
            'year': year,
            'file_name': fileName,
            'storage_path': storagePath,
            'file_size_bytes': fileSizeBytes,
            'page_count': pageCount,
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
      final fileOptions = const FileOptions(
        contentType: 'application/pdf',
        upsert: false,
      );

      try {
        final signed = await client.storage
            .from(_bucket)
            .createSignedUploadUrl(storagePath);
        // Prefer doing an HTTP PUT to the provided signed URL so we can
        // stream and report upload progress. The signed URL is provided
        // in `signed.signedUrl`.
        final signedUrl = signed.signedUrl;
        if (signedUrl.isNotEmpty) {
          final uri = Uri.parse(signedUrl);
          final httpClient = HttpClient();
          final req = await httpClient.putUrl(uri);
          req.headers.set('content-type', 'application/pdf');

          final total = await file.length();
          int sent = 0;

          final stream = file.openRead().transform(
            StreamTransformer<List<int>, List<int>>.fromHandlers(
              handleData: (data, sink) {
                sent += data.length;
                try {
                  onProgress?.call(sent, total);
                } catch (_) {}
                sink.add(data);
              },
            ),
          );

          await req.addStream(stream);
          final resp = await req.close();
          if (resp.statusCode < 200 || resp.statusCode > 299) {
            throw Exception('Signed URL upload failed: ${resp.statusCode}');
          }
        } else {
          // Fallback to SDK helper if signedUrl not available
          await client.storage
              .from(_bucket)
              .uploadToSignedUrl(signed.path, signed.token, file, fileOptions);
        }
      } catch (signedUploadError) {
        debugPrint(
          'Signed upload failed, falling back to direct upload: $signedUploadError',
        );
        // Use SDK direct upload as last-resort fallback.
        await client.storage
            .from(_bucket)
            .upload(storagePath, file, fileOptions: fileOptions);
      }

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
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final data = Uint8List.fromList(bytes);
      final fileOptions = const FileOptions(
        contentType: 'application/pdf',
        upsert: false,
      );

      try {
        final signed = await client.storage
            .from(_bucket)
            .createSignedUploadUrl(storagePath);
        final signedUrl = signed.signedUrl;
        if (signedUrl.isNotEmpty) {
          final uri = Uri.parse(signedUrl);
          final httpClient = HttpClient();
          final req = await httpClient.putUrl(uri);
          req.headers.set('content-type', 'application/pdf');

          final total = data.length;
          int sent = 0;

          // Chunk bytes to avoid a single large add() and to emit progress.
          const chunkSize = 64 * 1024;
          final controller = StreamController<List<int>>();
          () async {
            for (var offset = 0; offset < data.length; offset += chunkSize) {
              final end = (offset + chunkSize < data.length)
                  ? offset + chunkSize
                  : data.length;
              final chunk = data.sublist(offset, end);
              sent += chunk.length;
              try {
                onProgress?.call(sent, total);
              } catch (_) {}
              controller.add(chunk);
              await Future.delayed(Duration.zero);
            }
            await controller.close();
          }();

          await req.addStream(controller.stream);
          final resp = await req.close();
          if (resp.statusCode < 200 || resp.statusCode > 299) {
            throw Exception('Signed bytes upload failed: ${resp.statusCode}');
          }
        } else {
          await client.storage
              .from(_bucket)
              .uploadBinaryToSignedUrl(
                signed.path,
                signed.token,
                data,
                fileOptions,
              );
        }
      } catch (signedUploadError) {
        debugPrint(
          'Signed bytes upload failed, falling back to direct upload: $signedUploadError',
        );
        await client.storage
            .from(_bucket)
            .uploadBinary(storagePath, data, fileOptions: fileOptions);
      }
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
            id, category, sub_category, file_name, storage_path, year,
            page_count, file_size_bytes, uploaded_at, processing_status,
            categories!category(name, color_hex, slug)
          ''')
          .order('uploaded_at', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getRecentDocuments error: $e');
      return [];
    }
  }
}
