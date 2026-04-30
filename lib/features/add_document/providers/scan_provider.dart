import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// ── Scanned Page Model ──
class ScannedPage {
  final String id;
  final String originalPath;   // path before any filter
  String currentPath;          // path after filter applied
  String activeFilter;         // 'original','magic','bw','gray','lighten','darken'
  bool isProcessing;

  ScannedPage({
    required this.id,
    required this.originalPath,
    required this.currentPath,
    this.activeFilter = 'magic',
    this.isProcessing = false,
  });

  ScannedPage copyWith({
    String? currentPath,
    String? activeFilter,
    bool? isProcessing,
  }) {
    return ScannedPage(
      id: id,
      originalPath: originalPath,
      currentPath: currentPath ?? this.currentPath,
      activeFilter: activeFilter ?? this.activeFilter,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

// ── Scanner Filter Definition ──
class ScanFilter {
  final String id;
  final String label;
  final IconData icon;

  const ScanFilter({
    required this.id,
    required this.label,
    required this.icon,
  });
}

const List<ScanFilter> kScanFilters = [
  ScanFilter(id: 'original', label: 'Original',    icon: Icons.image_rounded),
  ScanFilter(id: 'magic',    label: 'Magic Color', icon: Icons.auto_fix_high_rounded),
  ScanFilter(id: 'bw',       label: 'B & W',       icon: Icons.filter_b_and_w_rounded),
  ScanFilter(id: 'gray',     label: 'Grayscale',   icon: Icons.gradient_rounded),
  ScanFilter(id: 'lighten',  label: 'Lighten',     icon: Icons.brightness_high_rounded),
  ScanFilter(id: 'darken',   label: 'Darken',      icon: Icons.brightness_low_rounded),
];

// ── Scanned Pages Notifier ──
class ScannedPagesNotifier extends Notifier<List<ScannedPage>> {
  @override
  List<ScannedPage> build() => [];

  void addPage(ScannedPage page) {
    state = [...state, page];
  }

  void removePage(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void updatePage(String id, ScannedPage updated) {
    state = state.map((p) => p.id == id ? updated : p).toList();
  }

  void reorderPages(int oldIndex, int newIndex) {
    final list = List<ScannedPage>.from(state);
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }

  void clear() {
    state = [];
  }

  List<String> get allCurrentPaths =>
    state.map((p) => p.currentPath).toList();
}

final scannedPagesProvider =
  NotifierProvider<ScannedPagesNotifier, List<ScannedPage>>(
    ScannedPagesNotifier.new,
  );

// ── Legacy compatibility (keep for other files) ──
class ScanImagesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];
  void add(String path) => state = [...state, path];
  void removeAt(int index) => state = [...state]..removeAt(index);
  void clear() => state = [];
}

final scanImagesProvider =
  NotifierProvider<ScanImagesNotifier, List<String>>(ScanImagesNotifier.new);
