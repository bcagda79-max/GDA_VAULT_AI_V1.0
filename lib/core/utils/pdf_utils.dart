import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfUtils {
  // Increase parse threshold so medium-large PDFs (e.g. ~100MB) will still
  // be parsed for an accurate page count. Beware of memory use on very large files.
  static const int _maxParseSizeBytes = 200 * 1024 * 1024;

  /// Returns the page count of a PDF file.
  static Future<int> getPageCount(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.length() > _maxParseSizeBytes) {
        // Avoid loading very large PDFs into memory just to read page count.
        return 1;
      }
      final List<int> bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final int pageCount = document.pages.count;
      document.dispose();
      return pageCount;
    } catch (e) {
      // Fallback to 1 if parsing fails
      return 1;
    }
  }
}
