import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfUtils {
  static const int _maxParseSizeBytes = 200 * 1024 * 1024;

  static Future<int> getPageCount(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.length() > _maxParseSizeBytes) {
        return 1;
      }
      final List<int> bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final int pageCount = document.pages.count;
      document.dispose();
      return pageCount;
    } catch (e) {
      return 1;
    }
  }
}
