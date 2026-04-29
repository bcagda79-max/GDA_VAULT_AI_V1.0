// lib/models/document_model.dart

/// Represents a single document file.
class DocumentModel {
  final String id;
  final String categoryId;
  final String yearLabel; // "1996", "2001-2004", "2026-onwards"
  final int yearStart;
  final int? yearEnd;
  final String fileName;
  final String filePath; // mock path for now
  final int pageCount;
  final DateTime uploadedAt;
  final bool isOngoing;

  DocumentModel({
    required this.id,
    required this.categoryId,
    required this.yearLabel,
    required this.yearStart,
    this.yearEnd,
    required this.fileName,
    required this.filePath,
    required this.pageCount,
    required this.uploadedAt,
    this.isOngoing = false,
  });
}
