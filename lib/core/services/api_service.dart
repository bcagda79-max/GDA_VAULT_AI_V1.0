import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gda_vault_ai/core/services/api_client.dart';
import 'package:gda_vault_ai/core/constants/supabase_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart' as dio;

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final ApiClient _apiClient = ApiClient.instance;

  List<Map<String, dynamic>>? _categoryCache;

  // ══════════════════════════════════════════════
  // CATEGORY OPERATIONS
  // ══════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final response = await _apiClient.get('/categories');
      if (response.statusCode == 200) {
        final categories = List<Map<String, dynamic>>.from(response.data);
        _categoryCache = categories;
        return categories;
      }
      return [];
    } catch (e) {
      debugPrint('getAllCategories error: $e');
      return [];
    }
  }

  Future<String?> resolveCategoryId(String categoryKey) async {
    final cached = _categoryCache ?? await getAllCategories();
    final match = cached.firstWhere(
      (row) =>
          row['id']?.toString() == categoryKey ||
          row['slug']?.toString() == categoryKey,
      orElse: () => <String, dynamic>{},
    );
    if (match.isNotEmpty) return match['id']?.toString();
    return null;
  }

  Future<List<Map<String, dynamic>>> getSubCategories(String parentId) async {
    final all = await getAllCategories();
    return all.where((c) => c['parent_id']?.toString() == parentId).toList();
  }

  Future<List<Map<String, dynamic>>> getTopLevelCategories() async {
    final all = await getAllCategories();
    return all.where((c) => c['parent_id'] == null).toList();
  }

  // ══════════════════════════════════════════════
  // DOCUMENT OPERATIONS
  // ══════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> _getAllDocuments() async {
    try {
      final response = await _apiClient.get('/documents');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('_getAllDocuments error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getDocumentByPath(String path) async {
    final docs = await _getAllDocuments();
    final match = docs.firstWhere((d) => d['storage_path'] == path, orElse: () => {});
    return match.isNotEmpty ? match : null;
  }

  Future<List<Map<String, dynamic>>> getDocumentsByCategory(
    String categoryKey, {
    String? subCategoryId,
  }) async {
    final categoryId = await resolveCategoryId(categoryKey);
    if (categoryId == null || categoryId.isEmpty) return [];

    final docs = await _getAllDocuments();
    return docs.where((d) {
      return d['category']?.toString() == categoryId || 
             d['sub_category']?.toString() == categoryId;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getDocumentsByYear(
    String categoryKey,
    int year,
  ) async {
    final docs = await getDocumentsByCategory(categoryKey);
    return docs.where((d) => d['year'] == year).toList();
  }

  Future<List<int>> getAvailableYears(String categoryId) async {
    final resolvedCategoryId = await resolveCategoryId(categoryId);
    if (resolvedCategoryId == null || resolvedCategoryId.isEmpty) return [];

    final docs = await getDocumentsByCategory(resolvedCategoryId);
    final years = docs
        .map<int>((row) {
          final value = row['year'];
          if (value is int) return value;
          if (value is num) return value.toInt();
          return int.tryParse(value?.toString() ?? '') ?? 0;
        })
        .where((y) => y > 0)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    return years;
  }

  // ══════════════════════════════════════════════
  // DASHBOARD STATS
  // ══════════════════════════════════════════════

  Future<Map<String, dynamic>> getDashboardStats() async {
    final docs = await _getAllDocuments();
    final cats = await getAllCategories();
    
    int totalPages = 0;
    double totalSizeGb = 0.0;
    
    for (var doc in docs) {
      totalPages += (doc['page_count'] as int?) ?? 0;
      final sizeBytes = (doc['file_size_bytes'] as int?) ?? 0;
      totalSizeGb += sizeBytes / (1024 * 1024 * 1024);
    }

    return {
      'total_documents': docs.length,
      'total_pages': totalPages,
      'total_size_gb': totalSizeGb,
      'category_count': cats.length,
    };
  }

  Future<List<Map<String, dynamic>>> getRecentDocuments() async {
    final docs = await _getAllDocuments();
    // Assuming uploaded_at is an ISO string
    docs.sort((a, b) => (b['uploaded_at'] ?? '').compareTo(a['uploaded_at'] ?? ''));
    return docs.take(10).toList();
  }

  // Placeholder for storage methods since Supabase is removed
  Future<String?> getSignedUrl(String storagePath) async {
    // Return a dummy url or you can implement a FastAPI endpoint for this later
    return "\${ApiClient.baseUrl}/files/\$storagePath";
  }

  Future<File?> downloadPdf(String storagePath, String localFileName) async {
    // Dummy download implementation, in reality you'd download from ApiClient
    return null;
  }

  Future<Map<String, dynamic>?> findDocumentByMetadata({
    required String categoryName,
    required String fileName,
    required String year,
  }) async {
    final docs = await _getAllDocuments();
    final match = docs.firstWhere((d) => d['file_name'] == fileName, orElse: () => {});
    return match.isNotEmpty ? match : null;
  }

  Future<Map<String, dynamic>> createCategory({
    required String name,
    required String storagePath,
    required String colorHex,
    required String iconName,
  }) async {
    final response = await _apiClient.post('/categories', data: {
      'name': name,
      'storage_path': storagePath,
      'color_hex': colorHex,
      'icon_name': iconName,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      // Clear cache so next fetch gets updated categories
      _categoryCache = null;
      return response.data;
    }
    throw Exception('Failed to create category');
  }

  Future<Map<String, dynamic>> createSubCategory({
    required String name,
    required String parentId,
    required String storagePath,
    required String colorHex,
    required String iconName,
  }) async {
    final response = await _apiClient.post('/categories', data: {
      'name': name,
      'parent_id': parentId,
      'storage_path': storagePath,
      'color_hex': colorHex,
      'icon_name': iconName,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      // Clear cache
      _categoryCache = null;
      return response.data;
    }
    throw Exception('Failed to create subcategory');
  }

  String buildStoragePath({
    required String categoryStoragePath,
    required String year,
    required String fileName,
  }) {
    return '$categoryStoragePath/$year/$fileName';
  }

  Future<String?> uploadPdf({
    required File file,
    required String storagePath,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        'storage_path': storagePath,
        'file': await dio.MultipartFile.fromFile(file.path, filename: storagePath.split('/').last),
      });
      final response = await _apiClient.dio.post(
        '/upload',
        data: formData,
        onSendProgress: onProgress,
      );
      if (response.statusCode == 200) {
        return storagePath;
      }
    } catch (e) {
      debugPrint('uploadPdf error: $e');
    }
    return null;
  }

  Future<String?> uploadPdfBytes({
    required Uint8List bytes,
    required String storagePath,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        'storage_path': storagePath,
        'file': dio.MultipartFile.fromBytes(bytes, filename: storagePath.split('/').last),
      });
      final response = await _apiClient.dio.post(
        '/upload',
        data: formData,
        onSendProgress: onProgress,
      );
      if (response.statusCode == 200) {
        return storagePath;
      }
    } catch (e) {
      debugPrint('uploadPdfBytes error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> insertDocument({
    required String category,
    String? subCategory,
    required int year,
    required String fileName,
    required String storagePath,
    required int fileSizeBytes,
    required int pageCount,
  }) async {
    try {
      final response = await _apiClient.post('/documents', data: {
        'category': category,
        'sub_category': subCategory,
        'year': year,
        'file_name': fileName,
        'storage_path': storagePath,
        'file_size_bytes': fileSizeBytes,
        'page_count': pageCount,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('insertDocument error: $e');
    }
    return null;
  }
}
