import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
// removed unused imports
import 'package:gda_vault_ai/features/add_document/providers/scan_provider.dart';

/// Allows reviewing and basic editing of scanned pages before categorization.
class ScanReviewScreen extends ConsumerStatefulWidget {
  final int pageCount;
  final String source;
  final List<String> imagePaths;

  const ScanReviewScreen({
    super.key,
    required this.pageCount,
    required this.source,
    this.imagePaths = const [],
  });

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isProcessing = false;
  late List<String> _currentPaths;
  late String _fileName;
  final Map<int, String> _originalPaths = {};
  final Map<int, bool> _isBW = {};
  final Map<int, bool> _isEnhanced = {};
  final Map<int, List<Offset>> _drawings = {};
  bool _isDrawingMode = false;

  // Interactive Crop Corners (Normalized 0.0 to 1.0)
  Offset _tl = const Offset(0.05, 0.05);
  Offset _tr = const Offset(0.95, 0.05);
  Offset _bl = const Offset(0.05, 0.95);
  Offset _br = const Offset(0.95, 0.95);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _currentPaths = List.from(widget.imagePaths);
    _fileName =
        "Scan_${DateFormat('dd_MM_yyyy_HHmm').format(DateTime.now())}.pdf";
    for (int i = 0; i < _currentPaths.length; i++) {
      _originalPaths[i] = _currentPaths[i];
    }
    // Default to B&W for the first page to meet user request
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilter(0, isBW: true);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _applyFilter(
    int index, {
    bool isBW = false,
    bool isEnhanced = false,
  }) async {
    setState(() => _isProcessing = true);
    try {
      final originalPath = _originalPaths[index]!;
      final bytes = await File(originalPath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image != null) {
        if (isBW) {
          // Real professional B&W thresholding
          image = img.grayscale(image);
          // Increase contrast first
          image = img.contrast(image, contrast: 250);
          // Simple but effective thresholding simulation
          image = img.adjustColor(image, brightness: 1.3);
        } else if (isEnhanced) {
          // Magic Color: Enhance colors and text clarity
          image = img.adjustColor(
            image,
            contrast: 1.5,
            brightness: 1.1,
            saturation: 1.2,
            gamma: 0.9,
          );
          // Strong Sharpening for text
          image = img.convolution(
            image,
            filter: [-0.5, -1.0, -0.5, -1.0, 7.0, -1.0, -0.5, -1.0, -0.5],
          );
        }

        final tempDir = await getTemporaryDirectory();
        final filteredPath =
            '${tempDir.path}/pro_filtered_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(
          filteredPath,
        ).writeAsBytes(img.encodeJpg(image, quality: 95));

        if (mounted) {
          setState(() {
            _currentPaths[index] = filteredPath;
            _isBW[index] = isBW;
            _isEnhanced[index] = isEnhanced;
          });
        }
      }
    } catch (e) {
      debugPrint("Pro Filter Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _saveAndProceed() {
    context.push(
      '/dashboard/add/select-category',
      extra: {
        'source': widget.source,
        'pageCount': _currentPaths.length,
        'imagePaths': _currentPaths,
        'fileName': _fileName,
      },
    );
  }

  Future<void> _shareAsPdf() async {
    setState(() => _isProcessing = true);
    try {
      final pdf = pw.Document();
      for (final path in _currentPaths) {
        final image = pw.MemoryImage(File(path).readAsBytesSync());
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Center(child: pw.Image(image)),
          ),
        );
      }
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/$_fileName");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Scanned Document');
    } catch (e) {
      debugPrint("Share Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveToDevice() async {
    _showRenameDialog(
      onComplete: (newName) async {
        setState(() {
          _fileName = newName;
          _isProcessing = true;
        });
        try {
          final pdf = pw.Document();
          for (final path in _currentPaths) {
            final image = pw.MemoryImage(File(path).readAsBytesSync());
            pdf.addPage(
              pw.Page(
                build: (pw.Context context) =>
                    pw.Center(child: pw.Image(image)),
              ),
            );
          }
          final output =
              await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
          final file = File("${output.path}/$_fileName");
          await file.writeAsBytes(await pdf.save());

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Saved to: ${file.path}"),
                backgroundColor: AppColors.gdaGreen,
              ),
            );
          }
        } catch (e) {
          debugPrint("Save Error: $e");
        } finally {
          if (mounted) setState(() => _isProcessing = false);
        }
      },
    );
  }

  void _showRenameDialog({required Function(String) onComplete}) {
    final controller = TextEditingController(
      text: _fileName.replaceAll(".pdf", ""),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          "Save Document",
          style: AppTextStyles.dmSans.copyWith(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter file name",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.gold),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              onComplete("${controller.text}.pdf");
              context.pop();
            },
            child: const Text(
              "SAVE",
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reindexMaps() {
    _originalPaths.clear();
    final oldIsBW = Map<int, bool>.from(_isBW);
    final oldIsEnhanced = Map<int, bool>.from(_isEnhanced);
    _isBW.clear();
    _isEnhanced.clear();
    for (int i = 0; i < _currentPaths.length; i++) {
      _originalPaths[i] = _currentPaths[i];
      // Try to preserve filter state by pulling nearest available value
      _isBW[i] = oldIsBW[i] ?? false;
      _isEnhanced[i] = oldIsEnhanced[i] ?? false;
    }
    setState(() {});
  }

  Future<void> _autoDetectAndCrop(int index) async {
    if (index < 0 || index >= _currentPaths.length) return;
    setState(() => _isProcessing = true);
    try {
      final path = _currentPaths[index];
      final bytes = await File(path).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return;

      // Downscale for detection to speed up processing
      const detectWidth = 600;
      final scale = image.width > detectWidth ? detectWidth / image.width : 1.0;
      final small = scale < 1.0
          ? img.copyResize(image, width: (image.width * scale).round())
          : image;

      // Compute approximate threshold using mean luminance
      int sum = 0;
      int samples = 0;
      final sx = small.width;
      final sy = small.height;
      const step = 3; // sampling step
      for (int y = 0; y < sy; y += step) {
        for (int x = 0; x < sx; x += step) {
          final p = small.getPixel(x, y);
          final r = p.r;
          final g = p.g;
          final b = p.b;
          final int lum = (0.299 * r + 0.587 * g + 0.114 * b).round();
          sum += lum;
          samples++;
        }
      }
      final mean = samples > 0 ? (sum / samples) : 255.0;
      final thresh = (mean * 0.92).round(); // slightly below mean

      int minX = sx, minY = sy, maxX = 0, maxY = 0;
      for (int y = 0; y < sy; y += 1) {
        for (int x = 0; x < sx; x += 1) {
          final p = small.getPixel(x, y);
          final r = p.r;
          final g = p.g;
          final b = p.b;
          final int lum = (0.299 * r + 0.587 * g + 0.114 * b).round();
          if (lum < thresh) {
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
      }

      // If we didn't find any dark pixels, try relaxing threshold a few times
      if (minX >= maxX || minY >= maxY) {
        bool found = false;
        for (final factor in [0.85, 0.75, 0.6]) {
          final t = (mean * factor).round();
          int tMinX = sx, tMinY = sy, tMaxX = 0, tMaxY = 0;
          for (int y = 0; y < sy; y++) {
            for (int x = 0; x < sx; x++) {
              final p = small.getPixel(x, y);
              final r = p.r;
              final g = p.g;
              final b = p.b;
              final int lum = (0.299 * r + 0.587 * g + 0.114 * b).round();
              if (lum < t) {
                if (x < tMinX) tMinX = x;
                if (x > tMaxX) tMaxX = x;
                if (y < tMinY) tMinY = y;
                if (y > tMaxY) tMaxY = y;
              }
            }
          }
          if (tMinX < tMaxX && tMinY < tMaxY) {
            minX = tMinX;
            minY = tMinY;
            maxX = tMaxX;
            maxY = tMaxY;
            found = true;
            break;
          }
        }
        if (!found) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Auto-crop failed: page edges not detected'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Expand box a little (padding)
      final padX = ((maxX - minX) * 0.03).round();
      final padY = ((maxY - minY) * 0.03).round();
      minX = (minX - padX).clamp(0, sx - 1);
      minY = (minY - padY).clamp(0, sy - 1);
      maxX = (maxX + padX).clamp(0, sx - 1);
      maxY = (maxY + padY).clamp(0, sy - 1);

      // Convert small coords back to original image coords
      final invScale = image.width / small.width;
      final left = (minX * invScale).round();
      final top = (minY * invScale).round();
      final cropW = ((maxX - minX + 1) * invScale).round();
      final cropH = ((maxY - minY + 1) * invScale).round();

      // Save cropped image
      final cropped = img.copyCrop(
        image,
        x: left.clamp(0, image.width - 1),
        y: top.clamp(0, image.height - 1),
        width: cropW.clamp(1, image.width - left),
        height: cropH.clamp(1, image.height - top),
      );
      final tempDir = await getTemporaryDirectory();
      final outPath =
          '${tempDir.path}/auto_cropped_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(img.encodeJpg(cropped, quality: 95));

      if (mounted) {
        setState(() {
          _currentPaths[index] = outPath;
          _originalPaths[index] = outPath;
          // reset overlay to full
          _tl = const Offset(0.05, 0.05);
          _tr = const Offset(0.95, 0.05);
          _bl = const Offset(0.05, 0.95);
          _br = const Offset(0.95, 0.95);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-crop applied'),
            backgroundColor: AppColors.gdaGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Auto-crop error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-crop failed'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cropCurrentPage() async {
    await _autoDetectAndCrop(_currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Review & Save",
          style: AppTextStyles.playfairDisplay.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Inline filename edit
          IconButton(
            tooltip: 'Rename PDF',
            onPressed: () => _showRenameDialog(
              onComplete: (newName) => setState(() => _fileName = newName),
            ),
            icon: const Icon(
              Icons.drive_file_rename_outline,
              color: AppColors.gold,
            ),
          ),
          TextButton(
            onPressed: _saveToDevice,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.gold, width: 1),
              ),
              child: Text(
                "SAVE",
                style: AppTextStyles.dmSans.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Compare Badge
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.compare_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Compare",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 1. Image Preview with Crop Handles & Drawing
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _currentPaths.length,
                  physics: _isDrawingMode
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    return Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onPanUpdate: _isDrawingMode
                                ? (details) {
                                    setState(() {
                                      _drawings[index] =
                                          (_drawings[index] ?? [])
                                            ..add(details.localPosition);
                                    });
                                  }
                                : null,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LayoutBuilder(
                                  builder: (ctx, constraints) {
                                    return CustomPaint(
                                      foregroundPainter: DrawingPainter(
                                        _drawings[index] ?? [],
                                      ),
                                      child: SizedBox(
                                        width: constraints.maxWidth,
                                        height: constraints.maxHeight,
                                        child: Image.file(
                                          File(_currentPaths[index]),
                                          fit: BoxFit.fitWidth,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          if (!_isDrawingMode) _buildInteractiveCropOverlay(),
                        ],
                      ),
                    );
                  },
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  ),
                if (_isDrawingMode)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Row(
                      children: [
                        FloatingActionButton.small(
                          backgroundColor: AppColors.navyDark,
                          elevation: 0,
                          child: const Icon(Icons.undo, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              if (_drawings[_currentPage] != null &&
                                  _drawings[_currentPage]!.isNotEmpty) {
                                _drawings[_currentPage]!.removeLast();
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton.small(
                          backgroundColor: AppColors.gold,
                          child: const Icon(
                            Icons.check,
                            color: AppColors.navyDark,
                          ),
                          onPressed: () =>
                              setState(() => _isDrawingMode = false),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Page thumbnails (select any page quickly)
          _buildPageThumbnailStrip(),

          // 2. Filter Selector (Thumbnails)
          _buildFilterStrip(),

          // 4. Bottom Actions Toolbar
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildInteractiveCropOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            // Shroud (Outer area darkened)
            // CustomPaint(painter: CropShroudPainter(_tl, _tr, _bl, _br)),

            // Connecting Lines
            CustomPaint(
              size: Size(w, h),
              painter: CropBorderPainter(_tl, _tr, _bl, _br),
            ),

            // Interactive Handles
            _buildHandle(
              Alignment.topLeft,
              _tl,
              (newPos) => setState(() => _tl = newPos),
              w,
              h,
            ),
            _buildHandle(
              Alignment.topRight,
              _tr,
              (newPos) => setState(() => _tr = newPos),
              w,
              h,
            ),
            _buildHandle(
              Alignment.bottomLeft,
              _bl,
              (newPos) => setState(() => _bl = newPos),
              w,
              h,
            ),
            _buildHandle(
              Alignment.bottomRight,
              _br,
              (newPos) => setState(() => _br = newPos),
              w,
              h,
            ),
          ],
        );
      },
    );
  }

  Widget _buildHandle(
    Alignment alignment,
    Offset currentPos,
    Function(Offset) onUpdate,
    double w,
    double h,
  ) {
    return Positioned(
      left: currentPos.dx * w - 15,
      top: currentPos.dy * h - 15,
      child: GestureDetector(
        onPanUpdate: (details) {
          // Smooth the handle movement by interpolating towards the new position
          final nxRaw = (currentPos.dx * w + details.delta.dx) / w;
          final nyRaw = (currentPos.dy * h + details.delta.dy) / h;
          const double alpha = 0.6; // smoothing factor (0..1)
          final nx = (currentPos.dx * (1 - alpha) + nxRaw * alpha);
          final ny = (currentPos.dy * (1 - alpha) + nyRaw * alpha);
          onUpdate(Offset(nx.clamp(0.0, 1.0), ny.clamp(0.0, 1.0)));
        },
        child: Container(
          width: 30,
          height: 30,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageThumbnailStrip() {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _currentPaths.length,
        itemBuilder: (context, index) {
          final isActive = index == _currentPage;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() => _currentPage = index);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              width: isActive ? 78 : 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: isActive
                    ? Border.all(color: AppColors.gold, width: 2)
                    : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(_currentPaths[index]),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterStrip() {
    final filters = [
      {"name": "Original", "isBW": false, "isEnhanced": false},
      {"name": "B&W", "isBW": true, "isEnhanced": false},
      {"name": "Enhance", "isBW": false, "isEnhanced": true},
    ];
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected =
              (_isBW[_currentPage] == filter['isBW']) &&
              (_isEnhanced[_currentPage] == filter['isEnhanced']);

          return GestureDetector(
            onTap: () => _applyFilter(
              _currentPage,
              isBW: filter['isBW'] as bool,
              isEnhanced: filter['isEnhanced'] as bool,
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: isSelected
                          ? Border.all(color: AppColors.gold, width: 2)
                          : null,
                      image: DecorationImage(
                        image: FileImage(File(_currentPaths[_currentPage])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filter['name'] as String,
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 10,
                      color: isSelected
                          ? AppColors.gold
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.navyDark,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionItem(
            Icons.add_a_photo_outlined,
            "Add",
            onTap: () => context.pop(),
          ), // Pops back to scanner
          _buildActionItem(
            Icons.picture_as_pdf_outlined,
            "Edit PDF",
            onTap: _showEditPdfDialog,
          ),
          _buildActionItem(
            Icons.crop_free_outlined,
            "AutoCrop",
            onTap: _cropCurrentPage,
          ),
          _buildActionItem(Icons.share_outlined, "Share", onTap: _shareAsPdf),
          _buildActionItem(
            Icons.edit_outlined,
            "Markup",
            onTap: () => setState(() => _isDrawingMode = true),
          ),
          // Final Check Action
          GestureDetector(
            onTap: _saveAndProceed,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.navyDark,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPdfDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: Text(
            "Edit Pages",
            style: AppTextStyles.dmSans.copyWith(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _currentPaths.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(_currentPaths[index]),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    "Page ${index + 1}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    onPressed: () {
                      if (_currentPaths.length > 1) {
                        setState(() {
                          _currentPaths.removeAt(index);
                          try {
                            ref
                                .read(scanImagesProvider.notifier)
                                .removeAt(index);
                          } catch (_) {}
                          // Reindex internal maps so indexes remain consistent
                          _reindexMaps();
                          if (_currentPage >= _currentPaths.length) {
                            _currentPage = _currentPaths.length - 1;
                            _pageController.jumpToPage(_currentPage);
                          }
                        });
                        setDialogState(() {});
                      }
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                "Done",
                style: TextStyle(color: AppColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points;
  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

class CropBorderPainter extends CustomPainter {
  final Offset tl, tr, bl, br;
  CropBorderPainter(this.tl, this.tr, this.bl, this.br);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(tl.dx * size.width, tl.dy * size.height)
      ..lineTo(tr.dx * size.width, tr.dy * size.height)
      ..lineTo(br.dx * size.width, br.dy * size.height)
      ..lineTo(bl.dx * size.width, bl.dy * size.height)
      ..close();

    canvas.drawPath(path, paint);

    // Draw dots at corners
    final dotPaint = Paint()..color = AppColors.gold;
    canvas.drawCircle(
      Offset(tl.dx * size.width, tl.dy * size.height),
      4,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(tr.dx * size.width, tr.dy * size.height),
      4,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(bl.dx * size.width, bl.dy * size.height),
      4,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(br.dx * size.width, br.dy * size.height),
      4,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(CropBorderPainter oldDelegate) => true;
}
