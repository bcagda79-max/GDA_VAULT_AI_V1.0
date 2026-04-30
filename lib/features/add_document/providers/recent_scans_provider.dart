import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Provides a list of recent scanned files (PDF, JPG, PNG) sorted by most recent modification.
final recentScansProvider = FutureProvider<List<File>>((ref) async {
  // Use external storage if available, otherwise fallback to app documents.
  final Directory? extDir = await getExternalStorageDirectory();
  final Directory baseDir = extDir ?? await getApplicationDocumentsDirectory();
  if (!await baseDir.exists()) return [];

  final List<File> files = baseDir
      .listSync()
      .whereType<File>()
      .where((f) =>
          f.path.toLowerCase().endsWith('.pdf') ||
          f.path.toLowerCase().endsWith('.jpg') ||
          f.path.toLowerCase().endsWith('.png'))
      .toList();

  files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  return files;
});
