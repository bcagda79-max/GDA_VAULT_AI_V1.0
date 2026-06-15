// ignore_for_file: unused_element
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

import 'package:gda_vault_ai/features/add_document/providers/scan_provider.dart';

class _CropHandles {
  Offset tl, tr, bl, br;
  _CropHandles({
    required this.tl,
    required this.tr,
    required this.bl,
    required this.br,
  });
}

class ScanReviewScreen extends ConsumerStatefulWidget {
  final int pageCount;
  final String source;
  final List<String> imagePaths;
  final String? existingPdfPath;

  const ScanReviewScreen({
    super.key,
    required this.pageCount,
    required this.source,
    this.imagePaths = const [],
    this.existingPdfPath,
  });

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isProcessing = false;
  String _processingLabel = '';
  bool _isDrawingMode = false;
  final Map<int, List<List<Offset>>> _drawingStrokes = {};
  late String _fileName;

  // -- C11: Post-crop zoom animation --
  late AnimationController _cropZoomController;
  late Animation<double> _cropZoomAnim;
  bool _showCropZoom = false;

  // Filter preview cache
  final Map<int, Map<String, String?>> _filterCache = {};

  // C10: Crop handles (absolute px within preview)
  // ignore: unused_field
  final Map<int, _CropHandles> _cropHandles = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fileName =
        'GDA_Scan_${DateFormat('dd_MM_yyyy_HHmm').format(DateTime.now())}.pdf';

    // Post-crop zoom animation
    _cropZoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cropZoomAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.18,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.18,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_cropZoomController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPagesFromArgs();
    });
  }

  void _syncPagesFromArgs() {
    final provider = ref.read(scannedPagesProvider);
    if (provider.isEmpty && widget.imagePaths.isNotEmpty) {
      for (final path in widget.imagePaths) {
        ref
            .read(scannedPagesProvider.notifier)
            .addPage(
              ScannedPage(
                id: UniqueKey().toString(),
                originalPath: path,
                currentPath: path,
                activeFilter: 'bw',
              ),
            );
      }
    }
    _preGenerateAllPreviews(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cropZoomController.dispose();
    super.dispose();
  }

  Future<String?> _generatePreview(String sourcePath, String filterId) async {
    try {
      final bytes = await File(sourcePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // Downscale for fast preview (max 300px width)
      if (image.width > 300) {
        image = img.copyResize(image, width: 300);
      }

      image = _applyFilterLogic(image, filterId);
      if (image == null) return sourcePath;

      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/prev_${filterId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(path).writeAsBytes(img.encodeJpg(image, quality: 72));
      return path;
    } catch (e) {
      return null;
    }
  }

  img.Image? _applyFilterLogic(img.Image image, String filterId) {
    switch (filterId) {
      case 'original':
        return image;

      case 'magic':
        image = img.adjustColor(
          image,
          contrast: 1.55,
          brightness: 1.08,
          saturation: 0.65,
        );
        image = img.convolution(
          image,
          filter: [0, -1, 0, -1, 5.5, -1, 0, -1, 0],
        );
        return image;

      case 'bw':
        image = img.grayscale(image);
        image = img.contrast(image, contrast: 190);
        image = img.adjustColor(image, brightness: 1.18);
        image = img.convolution(
          image,
          filter: [0, -0.8, 0, -0.8, 4.2, -0.8, 0, -0.8, 0],
        );
        return image;

      case 'gray':
        image = img.grayscale(image);
        image = img.adjustColor(image, brightness: 1.08, contrast: 1.25);
        return image;

      case 'lighten':
        image = img.adjustColor(
          image,
          brightness: 1.45,
          contrast: 1.15,
          saturation: 0.8,
        );
        return image;

      case 'darken':
        image = img.adjustColor(image, brightness: 0.72, contrast: 1.45);
        image = img.convolution(
          image,
          filter: [0, -0.5, 0, -0.5, 3.0, -0.5, 0, -0.5, 0],
        );
        return image;

      default:
        return image;
    }
  }

  Future<void> _preGenerateAllPreviews(int pageIndex) async {
    final pages = ref.read(scannedPagesProvider);
    if (pageIndex >= pages.length) return;
    if (_filterCache.containsKey(pageIndex)) return;

    _filterCache[pageIndex] = {};
    final page = pages[pageIndex];

    for (final filter in kScanFilters) {
      final path = filter.id == 'original'
          ? page.originalPath
          : await _generatePreview(page.originalPath, filter.id);
      if (mounted) {
        setState(() {
          _filterCache[pageIndex]![filter.id] = path;
        });
      }
    }
  }

  Future<void> _applyFilter(String filterId) async {
    final pages = ref.read(scannedPagesProvider);
    if (_currentPage >= pages.length) return;
    final page = pages[_currentPage];
    if (page.activeFilter == filterId) return;

    setState(() {
      _isProcessing = true;
      _processingLabel =
          'Applying ${kScanFilters.firstWhere((f) => f.id == filterId).label}...';
    });

    try {
      final bytes = await File(page.originalPath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      String resultPath = page.originalPath;

      if (image != null && filterId != 'original') {
        final filtered = _applyFilterLogic(image, filterId);
        if (filtered != null) {
          final tempDir = await getTemporaryDirectory();
          resultPath =
              '${tempDir.path}/filter_${filterId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await File(
            resultPath,
          ).writeAsBytes(img.encodeJpg(filtered, quality: 94));
        }
      }

      ref
          .read(scannedPagesProvider.notifier)
          .updatePage(
            page.id,
            page.copyWith(currentPath: resultPath, activeFilter: filterId),
          );
    } catch (e) {
      debugPrint('Filter error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _openManualCrop() async {
    final pages = ref.read(scannedPagesProvider);
    if (_currentPage >= pages.length) return;
    final page = pages[_currentPage];
    final currentIdx = _currentPage;

    final croppedPath = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => _ManualCropScreen(imagePath: page.currentPath),
      ),
    );

    if (croppedPath != null && mounted) {
      ref
          .read(scannedPagesProvider.notifier)
          .updatePage(page.id, page.copyWith(currentPath: croppedPath));
      _filterCache.remove(currentIdx);
      await _preGenerateAllPreviews(currentIdx);

      setState(() => _showCropZoom = true);
      await _cropZoomController.forward(from: 0.0);
      if (mounted) setState(() => _showCropZoom = false);
    }
  }

  Future<void> _rotatePage(bool clockwise) async {
    final pages = ref.read(scannedPagesProvider);
    if (_currentPage >= pages.length) return;
    final page = pages[_currentPage];

    setState(() {
      _isProcessing = true;
      _processingLabel = 'Rotating...';
    });

    try {
      final bytes = await File(page.currentPath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image != null) {
        image = clockwise
            ? img.copyRotate(image, angle: 90)
            : img.copyRotate(image, angle: -90);

        final tempDir = await getTemporaryDirectory();
        final outPath =
            '${tempDir.path}/rot_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(outPath).writeAsBytes(img.encodeJpg(image, quality: 95));

        ref
            .read(scannedPagesProvider.notifier)
            .updatePage(page.id, page.copyWith(currentPath: outPath));

        _filterCache.remove(_currentPage);
        _preGenerateAllPreviews(_currentPage);
      }
    } catch (e) {
      debugPrint('Rotate error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareAsPdf() async {
    setState(() {
      _isProcessing = true;
      _processingLabel = 'Creating PDF...';
    });
    try {
      final pages = ref.read(scannedPagesProvider);
      final pdf = pw.Document();
      for (final page in pages) {
        final image = pw.MemoryImage(
          await File(page.currentPath).readAsBytes(),
        );
        pdf.addPage(
          pw.Page(build: (pw.Context ctx) => pw.Center(child: pw.Image(image))),
        );
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$_fileName');
      await file.writeAsBytes(await pdf.save());
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'GDA Document');
    } catch (e) {
      debugPrint('Share: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _goToPdfPreview() {
    final pages = ref.read(scannedPagesProvider);
    if (pages.isEmpty) return;

    context.push(
      '/dashboard/add/pdf-preview',
      extra: {
        'imagePaths': pages.map((p) => p.currentPath).toList(),
        'fileName': _fileName,
        'source': widget.source,
        'pageCount': pages.length,
      },
    );
  }

  void _showRenameDialog() {}

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(scannedPagesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(pages),
      body: pages.isEmpty
          ? Center(
              child: Text(
                'No pages',
                style: AppTextStyles.bodyMd.copyWith(color: Colors.white54),
              ),
            )
          : Column(
              children: [
                Expanded(child: _buildPageView(pages)),
                _buildThumbnailStrip(pages),
                _buildFilterStrip(pages),
                _buildActionBar(pages),
              ],
            ),
    );
  }

  AppBar _buildAppBar(List<ScannedPage> pages) {
    return AppBar(
      backgroundColor: AppTokens.lightBrandPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 19,
        ),
        onPressed: () => context.pop(),
      ),
      title: Column(
        children: [
          Text(
            'Review & Edit',
            style: AppTextStyles.headingMd.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _fileName,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMd.copyWith(
              fontSize: 9,
              color: AppTokens.lightBrandPrimary,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
          onPressed: _shareAsPdf,
          tooltip: 'Share as PDF',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.8),
        child: Container(
          height: 0.8,
          color: AppTokens.lightBrandPrimary.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Future<void> _saveToDevice() async {
    setState(() {
      _isProcessing = true;
      _processingLabel = 'Saving PDF to device...';
    });

    try {
      final pages = ref.read(scannedPagesProvider);
      final pdf = pw.Document();
      for (final page in pages) {
        final imgBytes = await File(page.currentPath).readAsBytes();
        final pdfImage = pw.MemoryImage(imgBytes);
        pdf.addPage(
          pw.Page(
            build: (pw.Context ctx) => pw.Center(child: pw.Image(pdfImage)),
          ),
        );
      }

      final dir =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();

      final file = File('${dir.path}/$_fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saved to ${file.path}',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTokens.lightBrandPrimary,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildPageView(List<ScannedPage> pages) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pages.length,
          onPageChanged: (i) {
            setState(() => _currentPage = i);
            _preGenerateAllPreviews(i);
          },
          itemBuilder: (_, i) {
            final page = pages[i];
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: AnimatedBuilder(
                  animation: _cropZoomAnim,
                  builder: (_, child) {
                    final scale = (_showCropZoom && i == _currentPage)
                        ? _cropZoomAnim.value
                        : 1.0;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: GestureDetector(
                        onPanUpdate: _isDrawingMode
                            ? (d) {
                                setState(() {
                                  final strokes = _drawingStrokes[i] ?? [];
                                  if (strokes.isEmpty || strokes.last.isEmpty) {
                                    strokes.add([d.localPosition]);
                                  } else {
                                    strokes.last.add(d.localPosition);
                                  }
                                  _drawingStrokes[i] = strokes;
                                });
                              }
                            : null,
                        onPanEnd: _isDrawingMode
                            ? (_) {
                                setState(() {
                                  _drawingStrokes[i] = [
                                    ...(_drawingStrokes[i] ?? []),
                                    [],
                                  ];
                                });
                              }
                            : null,
                        child: CustomPaint(
                          foregroundPainter: _DrawingPainter(
                            _drawingStrokes[i] ?? [],
                          ),
                          child: Image.file(
                            File(page.currentPath),
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Processing overlay
        if (_isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.65),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppTokens.lightBrandPrimary,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _processingLabel,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Drawing mode indicator overlay
        if (_isDrawingMode)
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _DrawControlBtn(
                  icon: Icons.undo_rounded,
                  label: 'Undo',
                  onTap: () {
                    setState(() {
                      final strokes = _drawingStrokes[_currentPage];
                      if (strokes != null && strokes.isNotEmpty) {
                        strokes.removeLast();
                        if (strokes.isNotEmpty && strokes.last.isEmpty) {
                          strokes.removeLast();
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                _DrawControlBtn(
                  icon: Icons.check_rounded,
                  label: 'Done',
                  color: AppTokens.lightBrandPrimary,
                  onTap: () => setState(() => _isDrawingMode = false),
                ),
              ],
            ),
          ),

        // Drawing mode banner
        if (_isDrawingMode)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.edit_rounded,
                    size: 12,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Markup Mode',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 10,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnailStrip(List<ScannedPage> pages) {
    return Container(
      height: 96,
      color: const Color(0xFF0D0D0D),
      child: Column(
        children: [
          Container(height: 0.5, color: Colors.white.withValues(alpha: 0.08)),
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: pages.length,
              onReorder: (oldIdx, newIdx) => ref
                  .read(scannedPagesProvider.notifier)
                  .reorderPages(oldIdx, newIdx),
              proxyDecorator: (child, index, animation) =>
                  Material(color: Colors.transparent, child: child),
              itemBuilder: (_, i) {
                final page = pages[i];
                final isActive = i == _currentPage;
                return GestureDetector(
                  key: ValueKey(page.id),
                  onTap: () {
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                    );
                    setState(() => _currentPage = i);
                    _preGenerateAllPreviews(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: isActive ? 60 : 50,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isActive
                            ? AppTokens.lightBrandPrimary
                            : Colors.white.withValues(alpha: 0.2),
                        width: isActive ? 2 : 0.8,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppTokens.lightBrandPrimary.withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Stack(
                        children: [
                          Image.file(
                            File(page.currentPath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            gaplessPlayback: true,
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppTokens.lightBrandPrimary.withValues(
                                  alpha: 0.85,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: AppTextStyles.bodyMd.copyWith(
                                  fontSize: 7,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterStrip(List<ScannedPage> pages) {
    if (pages.isEmpty) return const SizedBox.shrink();
    final currentActiveFilter = pages[_currentPage].activeFilter;
    final previewCache = _filterCache[_currentPage] ?? {};

    return Container(
      height: 104,
      color: const Color(0xFF111111),
      child: Column(
        children: [
          Container(height: 0.5, color: Colors.white.withValues(alpha: 0.06)),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: kScanFilters.length,
              itemBuilder: (_, i) {
                final filter = kScanFilters[i];
                final isSelected = currentActiveFilter == filter.id;
                final previewPath = previewCache[filter.id];

                return GestureDetector(
                  onTap: () => _applyFilter(filter.id),
                  child: Container(
                    margin: const EdgeInsets.only(right: 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 58 : 50,
                          height: isSelected ? 68 : 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? AppTokens.lightBrandPrimary
                                  : Colors.white.withValues(alpha: 0.2),
                              width: isSelected ? 2 : 0.8,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTokens.lightBrandPrimary.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: previewPath != null
                                ? Image.file(
                                    File(previewPath),
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                  )
                                : Container(
                                    color: const Color(0xFF2A2A2A),
                                    child: Center(
                                      child: Icon(
                                        filter.icon,
                                        size: 20,
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          filter.label,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 9,
                            color: isSelected
                                ? AppTokens.lightBrandPrimary
                                : Colors.white.withValues(alpha: 0.5),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(List<ScannedPage> pages) {
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
        left: 8,
        right: 8,
      ),
      decoration: const BoxDecoration(
        color: AppTokens.lightBrandPrimary,
        border: Border(top: BorderSide(color: Colors.white12, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ActionBtn(
            icon: Icons.add_a_photo_outlined,
            label: 'Add',
            onTap: () => context.pop(),
          ),
          _ActionBtn(
            icon: Icons.rotate_right_rounded,
            label: 'Rotate ?',
            onTap: () => _rotatePage(true),
          ),
          _ActionBtn(
            icon: Icons.rotate_left_rounded,
            label: 'Rotate ?',
            onTap: () => _rotatePage(false),
          ),
          _ActionBtn(
            icon: Icons.crop_rounded,
            label: 'Crop',
            onTap: _openManualCrop,
          ),
          _ActionBtn(
            icon: _isDrawingMode
                ? Icons.check_circle_rounded
                : Icons.edit_rounded,
            label: _isDrawingMode ? 'Done' : 'Markup',
            isActive: _isDrawingMode,
            onTap: () => setState(() => _isDrawingMode = !_isDrawingMode),
          ),
          _ActionBtn(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: Colors.redAccent,
            onTap: () {
              if (pages.length > 1) {
                final page = pages[_currentPage];
                ref.read(scannedPagesProvider.notifier).removePage(page.id);
                if (_currentPage >= pages.length - 1) {
                  setState(
                    () => _currentPage = (pages.length - 2).clamp(0, 999),
                  );
                }
              } else {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      'Discard Scan',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to discard this scan entirely?',
                      style: AppTextStyles.bodyMd,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppTokens.lightBrandPrimary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/dashboard');
                        },
                        child: Text(
                          'Discard',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          GestureDetector(
            onTap: _goToPdfPreview,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTokens.lightBrandPrimary, Color(0xFFDFB84A)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTokens.lightBrandPrimary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppTokens.lightBrandPrimary,
                    size: 22,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Preview',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTokens.lightBrandPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Drawing painter --
class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.85)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter old) => true;
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final Color? color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isActive ? AppTokens.lightBrandPrimary : Colors.white);
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.25 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 21),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 8.5,
                color: c.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _DrawControlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTokens.lightBrandPrimary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(fontSize: 8, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualCropScreen extends StatefulWidget {
  final String imagePath;
  const _ManualCropScreen({required this.imagePath});
  @override
  State<_ManualCropScreen> createState() => _ManualCropScreenState();
}

class _ManualCropScreenState extends State<_ManualCropScreen> {
  double left = 0.05, top = 0.05, right = 0.95, bottom = 0.95;
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    if (mounted) {
      setState(() {
        _aspectRatio = decoded.width / decoded.height;
      });
    }
  }

  void _update(Offset delta, Size size, int corner) {
    setState(() {
      double dx = delta.dx / size.width;
      double dy = delta.dy / size.height;
      if (corner == 0) {
        left += dx;
        top += dy;
      }
      if (corner == 1) {
        right += dx;
        top += dy;
      }
      if (corner == 2) {
        left += dx;
        bottom += dy;
      }
      if (corner == 3) {
        right += dx;
        bottom += dy;
      }
      left = left.clamp(0.0, right - 0.05);
      top = top.clamp(0.0, bottom - 0.05);
      right = right.clamp(left + 0.05, 1.0);
      bottom = bottom.clamp(top + 0.05, 1.0);
    });
  }

  void _updateEdge(Offset delta, Size size, int edge) {
    setState(() {
      double dx = delta.dx / size.width;
      double dy = delta.dy / size.height;
      if (edge == 0) {
        top += dy;
      } // Top
      if (edge == 1) {
        bottom += dy;
      } // Bottom
      if (edge == 2) {
        left += dx;
      } // Left
      if (edge == 3) {
        right += dx;
      } // Right

      left = left.clamp(0.0, right - 0.05);
      top = top.clamp(0.0, bottom - 0.05);
      right = right.clamp(left + 0.05, 1.0);
      bottom = bottom.clamp(top + 0.05, 1.0);
    });
  }

  Widget _corner(int idx, Alignment align) {
    return Align(
      alignment: align,
      child: GestureDetector(
        onPanUpdate: (d) {
          final box = context.findRenderObject() as RenderBox;
          _update(d.delta, box.size, idx);
        },
        child: Container(
          width: 44,
          height: 44,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppTokens.lightBrandPrimary,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _edge(int idx, Alignment align, bool isVertical) {
    return Align(
      alignment: align,
      child: GestureDetector(
        onPanUpdate: (d) {
          final box = context.findRenderObject() as RenderBox;
          _updateEdge(d.delta, box.size, idx);
        },
        child: Container(
          width: isVertical ? 44 : double.infinity,
          height: isVertical ? double.infinity : 44,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: isVertical ? 4 : 24,
              height: isVertical ? 24 : 4,
              decoration: BoxDecoration(
                color: AppTokens.lightBrandPrimary,
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _crop() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: AppTokens.lightBrandPrimary)),
    );

    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image != null) {
        int x = (left * image.width).round();
        int y = (top * image.height).round();
        int w = ((right - left) * image.width).round();
        int h = ((bottom - top) * image.height).round();

        final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(path).writeAsBytes(img.encodeJpg(cropped, quality: 96));

        if (mounted) Navigator.pop(context);
        if (mounted) Navigator.pop(context, path);
      } else {
        if (mounted) Navigator.pop(context);
        if (mounted) Navigator.pop(context, null);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppTokens.lightBrandPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Crop Image',
          style: AppTextStyles.bodyMd.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.check_rounded,
              color: AppTokens.lightBrandPrimary,
              size: 26,
            ),
            onPressed: _crop,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _aspectRatio == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTokens.lightBrandPrimary),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: AspectRatio(
                  aspectRatio: _aspectRatio!,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.fill,
                        ),
                      ),
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;
                            return Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  right: 0,
                                  height: top * h,
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.6),
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  bottom: 0,
                                  right: 0,
                                  height: (1 - bottom) * h,
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.6),
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  top: top * h,
                                  bottom: (1 - bottom) * h,
                                  width: left * w,
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.6),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: top * h,
                                  bottom: (1 - bottom) * h,
                                  width: (1 - right) * w,
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.6),
                                  ),
                                ),

                                Positioned(
                                  left: left * w,
                                  top: top * h,
                                  right: (1 - right) * w,
                                  bottom: (1 - bottom) * h,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTokens.lightBrandPrimary,
                                        width: 2,
                                      ),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: -22,
                                          right: 0,
                                          child: _edge(
                                            0,
                                            Alignment.center,
                                            false,
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          bottom: -22,
                                          right: 0,
                                          child: _edge(
                                            1,
                                            Alignment.center,
                                            false,
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          bottom: 0,
                                          left: -22,
                                          child: _edge(
                                            2,
                                            Alignment.center,
                                            true,
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          bottom: 0,
                                          right: -22,
                                          child: _edge(
                                            3,
                                            Alignment.center,
                                            true,
                                          ),
                                        ),

                                        Positioned(
                                          left: -22,
                                          top: -22,
                                          child: _corner(0, Alignment.center),
                                        ),
                                        Positioned(
                                          right: -22,
                                          top: -22,
                                          child: _corner(1, Alignment.center),
                                        ),
                                        Positioned(
                                          left: -22,
                                          bottom: -22,
                                          child: _corner(2, Alignment.center),
                                        ),
                                        Positioned(
                                          right: -22,
                                          bottom: -22,
                                          child: _corner(3, Alignment.center),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

