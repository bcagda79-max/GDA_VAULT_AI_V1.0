import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
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
    _pageController = PageController();
    _currentPaths = List.from(widget.imagePaths);
    _fileName = "Scan_${DateFormat('dd_MM_yyyy_HHmm').format(DateTime.now())}.pdf";
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


  Future<void> _applyFilter(int index, {bool isBW = false, bool isEnhanced = false}) async {
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
          image = img.adjustColor(image, 
            contrast: 1.5, 
            brightness: 1.1, 
            saturation: 1.2,
            gamma: 0.9,
          );
          // Strong Sharpening for text
          image = img.convolution(image, filter: [
            -0.5, -1.0, -0.5,
            -1.0,  7.0, -1.0,
            -0.5, -1.0, -0.5
          ]);
        }

        final tempDir = await getTemporaryDirectory();
        final filteredPath = '${tempDir.path}/pro_filtered_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(filteredPath).writeAsBytes(img.encodeJpg(image, quality: 95));

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
    context.push('/dashboard/add/select-category', extra: {
      'source': widget.source,
      'pageCount': _currentPaths.length,
      'imagePaths': _currentPaths,
      'fileName': _fileName
    });
  }

  Future<void> _shareAsPdf() async {
    setState(() => _isProcessing = true);
    try {
      final pdf = pw.Document();
      for (final path in _currentPaths) {
        final image = pw.MemoryImage(File(path).readAsBytesSync());
        pdf.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Image(image))));
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
    _showRenameDialog(onComplete: (newName) async {
      setState(() {
        _fileName = newName;
        _isProcessing = true;
      });
      try {
        final pdf = pw.Document();
        for (final path in _currentPaths) {
          final image = pw.MemoryImage(File(path).readAsBytesSync());
          pdf.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Image(image))));
        }
        final output = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
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
    });
  }

  void _showRenameDialog({required Function(String) onComplete}) {
    final controller = TextEditingController(text: _fileName.replaceAll(".pdf", ""));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text("Save Document", style: AppTextStyles.dmSans.copyWith(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter file name",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              onComplete("${controller.text}.pdf");
              context.pop();
            },
            child: const Text("SAVE", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Review & Save",
          style: AppTextStyles.playfairDisplay.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _saveToDevice,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.gold, width: 1)),
              child: Text("SAVE", style: AppTextStyles.dmSans.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Row(children: [const Icon(Icons.compare_rounded, size: 14, color: Colors.white), const SizedBox(width: 4), Text("Compare", style: AppTextStyles.dmSans.copyWith(fontSize: 11, color: Colors.white))]),
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
                  physics: _isDrawingMode ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    return Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onPanUpdate: _isDrawingMode ? (details) {
                              setState(() {
                                _drawings[index] = (_drawings[index] ?? [])..add(details.localPosition);
                              });
                            } : null,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: CustomPaint(
                                  foregroundPainter: DrawingPainter(_drawings[index] ?? []),
                                  child: Image.file(
                                    File(_currentPaths[index]),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (!_isDrawingMode)
                            _buildInteractiveCropOverlay(),
                        ],
                      ),
                    );
                  },
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
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
                              if (_drawings[_currentPage] != null && _drawings[_currentPage]!.isNotEmpty) {
                                _drawings[_currentPage]!.removeLast();
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton.small(
                          backgroundColor: AppColors.gold,
                          child: const Icon(Icons.check, color: AppColors.navyDark),
                          onPressed: () => setState(() => _isDrawingMode = false),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

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
            _buildHandle(Alignment.topLeft, _tl, (newPos) => setState(() => _tl = newPos), w, h),
            _buildHandle(Alignment.topRight, _tr, (newPos) => setState(() => _tr = newPos), w, h),
            _buildHandle(Alignment.bottomLeft, _bl, (newPos) => setState(() => _bl = newPos), w, h),
            _buildHandle(Alignment.bottomRight, _br, (newPos) => setState(() => _br = newPos), w, h),
          ],
        );
      },
    );
  }

  Widget _buildHandle(Alignment alignment, Offset currentPos, Function(Offset) onUpdate, double w, double h) {
    return Positioned(
      left: currentPos.dx * w - 15,
      top: currentPos.dy * h - 15,
      child: GestureDetector(
        onPanUpdate: (details) {
          final nx = (currentPos.dx * w + details.delta.dx) / w;
          final ny = (currentPos.dy * h + details.delta.dy) / h;
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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
              ),
            ),
          ),
        ),
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
          final isSelected = (_isBW[_currentPage] == filter['isBW']) && (_isEnhanced[_currentPage] == filter['isEnhanced']);
          
          return GestureDetector(
            onTap: () => _applyFilter(_currentPage, isBW: filter['isBW'] as bool, isEnhanced: filter['isEnhanced'] as bool),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: isSelected ? Border.all(color: AppColors.gold, width: 2) : null,
                      image: DecorationImage(image: FileImage(File(_currentPaths[_currentPage])), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filter['name'] as String,
                    style: AppTextStyles.dmSans.copyWith(fontSize: 10, color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.6)),
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
      padding: EdgeInsets.only(top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(color: AppColors.navyDark, border: Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionItem(Icons.add_a_photo_outlined, "Add", onTap: () => context.pop()), // Pops back to scanner
          _buildActionItem(Icons.picture_as_pdf_outlined, "Edit PDF", onTap: _showEditPdfDialog),
          _buildActionItem(Icons.share_outlined, "Share", onTap: _shareAsPdf),
          _buildActionItem(Icons.edit_outlined, "Markup", onTap: () => setState(() => _isDrawingMode = true)),
          // Final Check Action
          GestureDetector(
            onTap: _saveAndProceed,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.check, color: AppColors.navyDark, size: 24),
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
          Text(label, style: AppTextStyles.dmSans.copyWith(fontSize: 10, color: Colors.white.withValues(alpha: 0.6))),
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
          title: Text("Edit Pages", style: AppTextStyles.dmSans.copyWith(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _currentPaths.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(_currentPaths[index]), width: 40, height: 40, fit: BoxFit.cover)),
                  title: Text("Page ${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () {
                    if (_currentPaths.length > 1) {
                      setState(() {
                        _currentPaths.removeAt(index);
                        ref.read(scanImagesProvider.notifier).removeAt(index);
                        // For simplicity in a mock, we just clear filter maps or re-sync
                        // In a real app we'd shift the keys in _isBW, _isEnhanced, etc.
                      });
                      setDialogState(() {});
                    }
                  }),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => context.pop(), child: const Text("Done", style: TextStyle(color: AppColors.gold))),
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
      if (points[i] != Offset.infinite && points[i+1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i+1], paint);
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
    canvas.drawCircle(Offset(tl.dx * size.width, tl.dy * size.height), 4, dotPaint);
    canvas.drawCircle(Offset(tr.dx * size.width, tr.dy * size.height), 4, dotPaint);
    canvas.drawCircle(Offset(bl.dx * size.width, bl.dy * size.height), 4, dotPaint);
    canvas.drawCircle(Offset(br.dx * size.width, br.dy * size.height), 4, dotPaint);
  }

  @override
  bool shouldRepaint(CropBorderPainter oldDelegate) => true;
}
