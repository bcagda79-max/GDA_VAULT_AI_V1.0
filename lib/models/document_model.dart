import 'package:flutter/material.dart';

/// Represents a single document file (Supabase-compatible).
class DocumentModel {
  final String id;
  final String categoryId;
  final String? subCategoryId;
  final int yearStart;
  final String fileName;

  /// Supabase Storage path (relative), or a local file path for local-only PDFs.
  final String storagePath;

  final String processingStatus;
  final int? fileSizeBytes;
  final int? pageCount;
  final DateTime uploadedAt;

  // UI helpers (not from DB — joined or computed)
  final String? categoryName;
  final Color? categoryColor;
  final String? categorySlug;

  const DocumentModel({
    required this.id,
    required this.categoryId,
    this.subCategoryId,
    required this.yearStart,
    required this.fileName,
    required this.storagePath,
    this.processingStatus = 'pending',
    this.fileSizeBytes,
    this.pageCount,
    required this.uploadedAt,
    this.categoryName,
    this.categoryColor,
    this.categorySlug,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': categoryId,
      'sub_category': subCategoryId,
      'year': yearStart,
      'file_name': fileName,
      'storage_path': storagePath,
      'processing_status': processingStatus,
      'file_size_bytes': fileSizeBytes,
      'page_count': pageCount,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    Color? color;
    final colorHex = map['categories']?['color_hex'] ?? map['color_hex'];
    if (colorHex != null) {
      try {
        color = Color(int.parse(colorHex.toString().replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return DocumentModel(
      id: map['id'].toString(),
      categoryId: map['category']?.toString() ?? '',
      subCategoryId: map['sub_category']?.toString(),
      yearStart: _asInt(map['year']) ?? 0,
      fileName: map['file_name']?.toString() ?? '',
      storagePath: map['storage_path']?.toString() ?? '',
      processingStatus: map['processing_status']?.toString() ?? 'pending',
      fileSizeBytes: _asInt(map['file_size_bytes']),
      pageCount: _asInt(map['page_count']),
      uploadedAt:
          DateTime.tryParse(map['uploaded_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      categoryName: map['categories']?['name']?.toString(),
      categoryColor: color,
      categorySlug: map['categories']?['slug']?.toString(),
    );
  }

  /// Year label for display
  String get yearLabel => yearStart.toString();

  bool get isLocalPath {
    final p = storagePath;
    return p.startsWith('/') || p.contains(':\\') || p.startsWith('file://');
  }

  String get fileSizeFormatted {
    if (fileSizeBytes == null) return 'Unknown size';
    final bytes = fileSizeBytes!;
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1048576) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(bytes / 1048576).toStringAsFixed(1)}MB';
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
