import 'package:flutter/material.dart';

/// Represents a single document file (Supabase-compatible).
class DocumentModel {
  final String id;
  final String categoryId;
  final String yearLabel;
  final int yearStart;
  final int? yearEnd;
  final String fileName;

  /// Supabase Storage path (relative), or a local file path for local-only PDFs.
  final String storagePath;

  final int? fileSizeBytes;
  final int? pageCount;
  final DateTime uploadedAt;
  final bool isActive;

  // UI helpers (not from DB — joined or computed)
  final String? categoryName;
  final Color? categoryColor;
  final String? categorySlug;

  const DocumentModel({
    required this.id,
    required this.categoryId,
    required this.yearLabel,
    required this.yearStart,
    this.yearEnd,
    required this.fileName,
    required this.storagePath,
    this.fileSizeBytes,
    this.pageCount,
    required this.uploadedAt,
    this.isActive = true,
    this.categoryName,
    this.categoryColor,
    this.categorySlug,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'year_label': yearLabel,
      'year_start': yearStart,
      'year_end': yearEnd,
      'file_name': fileName,
      'storage_path': storagePath,
      'file_size_bytes': fileSizeBytes,
      'page_count': pageCount,
      'uploaded_at': uploadedAt.toIso8601String(),
      'is_active': isActive,
      'category_name': categoryName,
      'category_slug': categorySlug,
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
      categoryId: map['category_id'].toString(),
      yearLabel: map['year_label']?.toString() ?? '',
      yearStart: _asInt(map['year_start']) ?? 0,
      yearEnd: _asInt(map['year_end']),
      fileName: map['file_name']?.toString() ?? '',
      storagePath: map['storage_path']?.toString() ?? '',
      fileSizeBytes: _asInt(map['file_size_bytes']),
      pageCount: _asInt(map['page_count']),
      uploadedAt:
          DateTime.tryParse(map['uploaded_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isActive: map['is_active'] as bool? ?? true,
      categoryName: map['categories']?['name']?.toString(),
      categoryColor: color,
      categorySlug: map['categories']?['slug']?.toString(),
    );
  }

  /// Used by existing UI to tag "ongoing" files.
  bool get isOngoing {
    final v = yearLabel.toLowerCase();
    return v.contains('ongoing') || v.contains('onwards');
  }

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
