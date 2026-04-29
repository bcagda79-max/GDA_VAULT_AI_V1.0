import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/features/add_document/widgets/scanner_frame_painter.dart';

/// A full-screen immersive scanner UI simulating a document scanner.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  bool _isFlashOn = false;
  bool _isAutoMode = true;
  final bool _isDocumentDetected = true; // Always true for mock
  bool _isCapturing = false;
  bool _showFlash = false;
  String _selectedFilter = 'Auto';
  final List<String> _scannedPages = [];

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: false);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    // Make status bar transparent for immersive feel
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _showFlash = true;
      });
      
      // Brief flash duration
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() => _showFlash = false);
      
      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        setState(() {
          _isCapturing = false;
          _scannedPages.add('scan_${DateTime.now().millisecondsSinceEpoch}.jpg');
        });

        if (_isAutoMode && _scannedPages.length == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Page captured! Tap again to add more pages"),
              action: SnackBarAction(
                label: "Done",
                onPressed: _proceedToReview,
                textColor: AppColors.gold,
              ),
              backgroundColor: AppColors.navyDark,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _proceedToReview() {
    if (_scannedPages.isEmpty) return;
    context.push('/dashboard/add/review', extra: {
      'pageCount': _scannedPages.length,
      'source': 'scanner',
    });
  }

  void _toggleFlash() => setState(() => _isFlashOn = !_isFlashOn);
  void _toggleMode() => setState(() => _isAutoMode = !_isAutoMode);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Viewfinder Mock
          _buildCameraMock(size),

          // 2. Scanning Overlay
          _buildScannerOverlay(size),

          // 3. Top Toolbar
          _buildTopToolbar(context),

          // 4. Bottom Controls
          _buildBottomControls(context, size),

          // 5. Flash Overlay
          if (_showFlash)
            Positioned.fill(
              child: Container(color: Colors.white).animate().fadeOut(duration: 300.ms),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraMock(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      color: const Color(0xFF1A1A1A),
      child: Stack(
        children: [
          // Noise/Vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.9,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
          // Mock Document
          Center(
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8 * 1.414,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5EE),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(4, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(r'C:\Users\KhizarLodhi\.gemini\antigravity\brain\15a09e33-eb84-429f-9b26-c14d2bc2e80e\official_gda_document_mockup_1777472683815.png'),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildMockDocFallback(size),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockDocFallback(Size size) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("KHYBER PAKHTUNKHWA", style: TextStyle(fontSize: 5, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: AppColors.charcoal.withOpacity(0.4))),
                  AppSpacing.vertical(2),
                  Text("Galiyat Development Authority", style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: AppColors.charcoal.withOpacity(0.7))),
                ],
              ),
              Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.catBoard.withOpacity(0.3), shape: BoxShape.circle)),
            ],
          ),
          AppSpacing.vertical(12),
          Container(height: 1, color: AppColors.charcoal.withOpacity(0.2)),
          AppSpacing.vertical(12),
          ...List.generate(8, (i) => Container(margin: const EdgeInsets.only(bottom: 6), height: 7, width: size.width * (0.4 + (i % 3) * 0.1), decoration: BoxDecoration(color: AppColors.charcoal.withOpacity(0.12), borderRadius: BorderRadius.circular(3)))),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(Size size) {
    const frameLeft = 0.1;
    const frameTop = 0.15;
    const frameRight = 0.9;
    const frameBottom = 0.78;

    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: ScannerFramePainter(),
        ),
        // Animated Scan Line
        AnimatedBuilder(
          animation: _scanAnimation,
          builder: (context, child) {
            final top = size.height * (frameTop + (frameBottom - frameTop) * _scanAnimation.value);
            return Positioned(
              top: top,
              left: size.width * frameLeft,
              child: Stack(
                children: [
                  Container(
                    height: 2,
                    width: size.width * (frameRight - frameLeft),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.gold,
                          AppColors.gold,
                          AppColors.gold,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                  Container(
                    height: 40,
                    width: size.width * (frameRight - frameLeft),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.gold.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Detected Badge
        if (_isDocumentDetected)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gdaGreen.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: Colors.white),
                    AppSpacing.horizontal(6),
                    Text(
                      "Document Detected",
                      style: AppTextStyles.dmSans.copyWith(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopToolbar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 12,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
              ),
            ),
            Column(
              children: [
                Text("Scanner", style: AppTextStyles.dmSans.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("Page ${_scannedPages.length + 1}", style: AppTextStyles.dmSans.copyWith(fontSize: 10, color: Colors.white.withOpacity(0.6))),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleFlash,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                    child: Icon(
                      _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      size: 20,
                      color: _isFlashOn ? AppColors.gold : Colors.white,
                    ),
                  ),
                ),
                AppSpacing.horizontal(8),
                GestureDetector(
                  onTap: _toggleMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      _isAutoMode ? "AUTO" : "MANUAL",
                      style: AppTextStyles.dmSans.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: _isAutoMode ? AppColors.gold : Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, Size size) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.85), Colors.transparent],
          ),
        ),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Original', 'Auto', 'B&W', 'Grayscale', 'Lighten'].map((mode) {
                  final isSelected = _selectedFilter == mode;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = mode),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(
                        mode,
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.navyDark : Colors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            AppSpacing.vertical(20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {}, // Gallery mock
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.photo_library_rounded, size: 24, color: Colors.white),
                  ),
                ),
                GestureDetector(
                  onTap: _capturePhoto,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                        ),
                      ),
                      AnimatedContainer(
                        width: _isCapturing ? 60 : 68,
                        height: _isCapturing ? 60 : 68,
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCapturing ? AppColors.gold : Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 12, spreadRadius: 2),
                          ],
                        ),
                        child: _isCapturing
                            ? const Center(child: CircularProgressIndicator(color: AppColors.navyDark, strokeWidth: 2))
                            : null,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_scannedPages.isNotEmpty) _showScannedPagesSheet();
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: _scannedPages.isEmpty
                            ? Icon(Icons.photo_outlined, size: 24, color: Colors.white.withOpacity(0.5))
                            : Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0EDE4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.description_rounded, size: 20, color: AppColors.charcoal.withOpacity(0.3)),
                              ),
                      ),
                      if (_scannedPages.isNotEmpty)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                "${_scannedPages.length}",
                                style: AppTextStyles.dmSans.copyWith(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.navyDark),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vertical(12),
            Center(
              child: Text(
                _isDocumentDetected ? "Document detected — tap to capture" : "Align document within the frame",
                style: AppTextStyles.dmSans.copyWith(fontSize: 11, color: Colors.white.withOpacity(0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScannedPagesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ScannedPagesSheet(
        scannedPages: _scannedPages,
        onDone: _proceedToReview,
        onDelete: (index) {
          setState(() => _scannedPages.removeAt(index));
          if (_scannedPages.isEmpty) Navigator.pop(context);
        },
      ),
    );
  }
}

class _ScannedPagesSheet extends StatelessWidget {
  final List<String> scannedPages;
  final VoidCallback onDone;
  final Function(int) onDelete;

  const _ScannedPagesSheet({
    required this.scannedPages,
    required this.onDone,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Scanned Pages (${scannedPages.length})",
                style: AppTextStyles.playfairDisplay.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: onDone,
                child: Text("Done →", style: AppTextStyles.dmSans.copyWith(color: AppColors.gold)),
              ),
            ],
          ),
          AppSpacing.vertical(12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: scannedPages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 80,
                  height: 110,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDE4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(child: Icon(Icons.description_rounded, size: 32, color: AppColors.charcoal.withOpacity(0.2))),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.navyDark.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                          child: Text("p.${index + 1}", style: AppTextStyles.dmSans.copyWith(fontSize: 8, color: Colors.white)),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onDelete(index),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          AppSpacing.vertical(12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.gold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo, color: AppColors.gold, size: 18),
                      AppSpacing.horizontal(8),
                      Text("Add More", style: AppTextStyles.dmSans.copyWith(color: AppColors.gold)),
                    ],
                  ),
                ),
              ),
              AppSpacing.horizontal(12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, color: AppColors.navyDark, size: 18),
                      AppSpacing.horizontal(8),
                      Text("Review & Save", style: AppTextStyles.dmSans.copyWith(color: AppColors.navyDark, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
