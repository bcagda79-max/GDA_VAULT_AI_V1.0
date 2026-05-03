import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:gda_vault_ai/core/services/supabase_service.dart';
import 'package:gda_vault_ai/core/utils/pdf_utils.dart';

/// Upload result model.
class UploadResult {
  final bool success;
  final String? documentId;
  final String? storagePath;
  final String? errorMessage;

  final Map<String, dynamic>? record;

  const UploadResult({
    required this.success,
    this.documentId,
    this.storagePath,
    this.errorMessage,
    this.record,
  });
}

/// Handles full upload pipeline:
/// PDF file/bytes → Supabase Storage → DB record insert.
class DocumentUploadService {
  DocumentUploadService._();
  static final DocumentUploadService instance = DocumentUploadService._();

  static const int maxPdfUploadSizeBytes = 200 * 1024 * 1024;
  static const String maxPdfUploadSizeLabel = '200 MB';

  final _supa = SupabaseService.instance;

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Upload a PDF file from device.
  Future<UploadResult> uploadPdfFile({
    required File pdfFile,
    required String category,
    String? subCategory,
    required String categoryStoragePath,
    required int year,
    required String fileName,
    int? pageCount,
    void Function(
      String phase,
      double progress, {
      int? bytesSent,
      int? totalBytes,
    })?
    onProgress,
  }) async {
    try {
      // Phase 1: Build path
      onProgress?.call('Preparing upload...', 0.1);
      // If caller didn't provide page count, attempt to read it now so UI shows accurate pages.
      int actualPageCount = pageCount ?? 0;
      try {
        if (actualPageCount == 0) {
          actualPageCount = await PdfUtils.getPageCount(pdfFile.path);
        }
      } catch (_) {
        // ignore - we'll fall back to whatever was provided or 1 later
      }
      final storagePath = _supa.buildStoragePath(
        categoryStoragePath: categoryStoragePath,
        year: year.toString(),
        fileName: fileName,
      );

      // Phase 2: Upload to storage
      onProgress?.call('Uploading to GDA Vault...', 0.3);
      final fileSizeBytes = await pdfFile.length();
      if (fileSizeBytes > maxPdfUploadSizeBytes) {
        return UploadResult(
          success: false,
          errorMessage:
              'PDF is ${formatBytes(fileSizeBytes)}. Maximum upload size is $maxPdfUploadSizeLabel.',
        );
      }
      final uploaded = await _supa.uploadPdf(
        file: pdfFile,
        storagePath: storagePath,
        onProgress: (sent, total) {
          // Map raw byte progress to the UI progress range (0.3 → 0.75)
          final fraction = total > 0 ? (sent / total) : 0.0;
          final uiProgress = 0.3 + (fraction * 0.45);
          try {
            onProgress?.call(
              'Uploading to GDA Vault...',
              uiProgress,
              bytesSent: sent,
              totalBytes: total,
            );
          } catch (_) {}
        },
      );

      if (uploaded == null) {
        return const UploadResult(
          success: false,
          errorMessage: 'File upload to storage failed',
        );
      }

      onProgress?.call('Saving document record...', 0.8);

      // Phase 3: Insert DB record
      final record = await _supa.insertDocument(
        category: category,
        subCategory: subCategory,
        year: year,
        fileName: fileName,
        storagePath: storagePath,
        fileSizeBytes: fileSizeBytes,
        pageCount: actualPageCount == 0 ? 1 : actualPageCount,
      );

      onProgress?.call('Complete!', 1.0);

      return UploadResult(
        success: true,
        documentId: record?['id']?.toString(),
        storagePath: storagePath,
        record: record,
      );
    } catch (e) {
      debugPrint('uploadPdfFile error: $e');
      return UploadResult(success: false, errorMessage: e.toString());
    }
  }

  /// Upload scanned images as a generated PDF.
  Future<UploadResult> uploadScannedImages({
    required List<String> imagePaths,
    required String category,
    String? subCategory,
    required String categoryStoragePath,
    required int year,
    required String fileName,
    void Function(
      String phase,
      double progress, {
      int? bytesSent,
      int? totalBytes,
    })?
    onProgress,
  }) async {
    try {
      // Phase 1: Convert images to PDF
      onProgress?.call('Generating PDF...', 0.15);
      final pdf = pw.Document();
      for (final path in imagePaths) {
        final imgBytes = await File(path).readAsBytes();
        final pdfImage = pw.MemoryImage(imgBytes);
        pdf.addPage(
          pw.Page(
            build: (pw.Context ctx) => pw.Center(child: pw.Image(pdfImage)),
          ),
        );
      }
      final pdfBytes = await pdf.save();

      if (pdfBytes.length > maxPdfUploadSizeBytes) {
        return UploadResult(
          success: false,
          errorMessage:
              'Generated PDF is ${formatBytes(pdfBytes.length)}. Maximum upload size is $maxPdfUploadSizeLabel.',
        );
      }

      // Phase 2: Upload bytes to storage
      onProgress?.call('Uploading to GDA Vault...', 0.4);
      final storagePath = _supa.buildStoragePath(
        categoryStoragePath: categoryStoragePath,
        year: year.toString(),
        fileName: fileName,
      );

      final uploaded = await _supa.uploadPdfBytes(
        bytes: pdfBytes,
        storagePath: storagePath,
        onProgress: (sent, total) {
          final fraction = total > 0 ? (sent / total) : 0.0;
          final uiProgress = 0.4 + (fraction * 0.45);
          try {
            onProgress?.call(
              'Uploading to GDA Vault...',
              uiProgress,
              bytesSent: sent,
              totalBytes: total,
            );
          } catch (_) {}
        },
      );

      if (uploaded == null) {
        return const UploadResult(
          success: false,
          errorMessage: 'Scanned PDF upload failed',
        );
      }

      onProgress?.call('Saving record...', 0.85);

      // Phase 3: DB record
      final record = await _supa.insertDocument(
        category: category,
        subCategory: subCategory,
        year: year,
        fileName: fileName,
        storagePath: storagePath,
        fileSizeBytes: pdfBytes.length,
        pageCount: imagePaths.length,
      );

      onProgress?.call('Done!', 1.0);

      return UploadResult(
        success: true,
        documentId: record?['id']?.toString(),
        storagePath: storagePath,
        record: record,
      );
    } catch (e) {
      debugPrint('uploadScannedImages error: $e');
      return UploadResult(success: false, errorMessage: e.toString());
    }
  }
}
