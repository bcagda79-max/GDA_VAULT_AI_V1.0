import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScanImagesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void add(String path) => state = [...state, path];
  void removeAt(int index) => state = [...state]..removeAt(index);
  void clear() => state = [];
}

final scanImagesProvider = NotifierProvider<ScanImagesNotifier, List<String>>(ScanImagesNotifier.new);

class ScanMetadataNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() => {
    'fileName': 'Scan_${DateTime.now().millisecondsSinceEpoch}.pdf',
    'source': 'scanner',
  };
}

final scanMetadataProvider = NotifierProvider<ScanMetadataNotifier, Map<String, dynamic>>(ScanMetadataNotifier.new);
