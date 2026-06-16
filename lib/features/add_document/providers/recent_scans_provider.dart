import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final recentScansProvider = FutureProvider<List<File>>((ref) async {
  if (kIsWeb) return [];
  
  try {
    final Directory? extDir = await getExternalStorageDirectory();
    final Directory baseDir = extDir ?? await getApplicationDocumentsDirectory();
    if (!await baseDir.exists()) return [];

    final List<File> files = baseDir
        .listSync()
        .whereType<File>()
        .where(
          (f) =>
              f.path.toLowerCase().endsWith('.pdf') ||
              f.path.toLowerCase().endsWith('.jpg') ||
              f.path.toLowerCase().endsWith('.png'),
        )
        .toList();

    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  } catch (e) {
    if (kDebugMode) {
      print('load recent opened error: $e');
    }
    return [];
  }
});
