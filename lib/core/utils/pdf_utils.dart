import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfUtils {
  /// Returns the page count of a PDF file.
  static Future<int> getPageCount(String filePath) async {
    try {
      final File file = File(filePath);
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
