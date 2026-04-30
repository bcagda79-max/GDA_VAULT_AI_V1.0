import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

import 'package:gda_vault_ai/features/add_document/providers/scan_provider.dart';

const _uuid = Uuid();

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isFlashOn = false;
  bool _isHighRes = true;
  bool _showGrid = false;
  bool _isCapturing = false;

  // Capture flash animation controller
  late AnimationController _flashController;
  late Animation<double> _flashAnim;

  // Brief scan line shown ONLY during capture processing
  late AnimationController _captureScanController;
  late Animation<double> _captureScanAnim;
  bool _showCaptureScan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Status bar: light icons (camera is dark bg)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Flash overlay animation (white flash on capture)
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flashAnim = Tween<double>(begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(
        parent: _flashController,
        curve: Curves.easeOut,
      ));

    // Capture scan line animation (shown briefly after capture tap)
    _captureScanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _captureScanAnim = Tween<double>(begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(
        parent: _captureScanController,
        curve: Curves.easeInOut,
      ));

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        back,
        _isHighRes ? ResolutionPreset.high : ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // ── C1: Lock zoom to 1x — no auto zoom-in ──
      if (_cameraController!.value.isInitialized) {
        try {
          await _cameraController!.setZoomLevel(1.0);
        } catch (e) {
          debugPrint('Zoom lock error: $e');
        }
      }

      if (mounted) setState(() => _isCameraReady = true);

    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Camera error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      if (mounted) {
        setState(() {
          _isCameraReady = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flashController.dispose();
    _captureScanController.dispose();
    _cameraController?.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    try {
      setState(() => _isFlashOn = !_isFlashOn);
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off);
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> _toggleResolution() async {
    setState(() {
      _isHighRes = !_isHighRes;
      _isCameraReady = false;
    });
    await _cameraController?.dispose();
    _cameraController = null;
    await _initCamera();
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || !_isCameraReady || _cameraController == null) return;

    setState(() {
      _isCapturing = true;
      _showCaptureScan = true;
    });

    // ── C6: Play scan animation during capture ──
    _captureScanController.forward(from: 0.0);
    HapticFeedback.mediumImpact();

    // White flash effect
    _flashController.forward(from: 0.0).then((_) {
      _flashController.reverse();
    });

    try {
      final xfile = await _cameraController!.takePicture();

      // Fix orientation
      String processedPath = xfile.path;
      try {
        final bytes = await File(xfile.path).readAsBytes();
        img.Image? decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final fixed = img.bakeOrientation(decoded);
          final tempDir = await getTemporaryDirectory();
          processedPath =
            '${tempDir.path}/gda_scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await File(processedPath)
            .writeAsBytes(img.encodeJpg(fixed, quality: 96));
        }
      } catch (e) {
        debugPrint('Orientation fix: $e');
      }

      // ── C7: Default filter = 'bw' (Black & White) ──
      final filteredPath = await _applyBWFilter(processedPath);

      final page = ScannedPage(
        id: _uuid.v4(),
        originalPath: processedPath,
        currentPath: filteredPath,
        activeFilter: 'bw',
      );

      ref.read(scannedPagesProvider.notifier).addPage(page);

      // Wait for scan animation to finish
      await Future.delayed(const Duration(milliseconds: 700));

      if (mounted) {
        setState(() {
          _isCapturing = false;
          _showCaptureScan = false;
        });

        final count = ref.read(scannedPagesProvider).length;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Page $count captured! Tap again for more.',
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 12, color: Colors.white),
              ),
            ),
          ]),
          backgroundColor: AppColors.gdaGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        ));
      }

    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _showCaptureScan = false;
        });
      }
    }
  }

  // ── Real B&W filter with professional document thresholding ──
  Future<String> _applyBWFilter(String sourcePath) async {
    try {
      final bytes = await File(sourcePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return sourcePath;

      image = img.grayscale(image);
      image = img.contrast(image, contrast: 180);
      image = img.adjustColor(image, brightness: 1.15);
      // Sharpen for text clarity
      image = img.convolution(image,
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]);

      final tempDir = await getTemporaryDirectory();
      final outPath =
        '${tempDir.path}/bw_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(img.encodeJpg(image, quality: 95));
      return outPath;
    } catch (e) {
      return sourcePath;
    }
  }

  void _proceedToReview() {
    final pages = ref.read(scannedPagesProvider);
    if (pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please capture at least one page first'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    context.push('/dashboard/add/review', extra: {
      'pageCount': pages.length,
      'source': 'scanner',
      'imagePaths': pages.map((p) => p.currentPath).toList(),
    });
  }

  void _showPagesSheet() {
    final pages = ref.read(scannedPagesProvider);
    if (pages.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ScannedPagesSheet(
        pages: pages,
        onDone: _proceedToReview,
        onDelete: (id) =>
          ref.read(scannedPagesProvider.notifier).removePage(id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(scannedPagesProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(scannedPagesProvider.notifier).clear();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,

        // ── C3: Solid GDA-style AppBar (NOT transparent) ──
        appBar: _buildGdaAppBar(),

        body: Column(
          children: [
            // ── C4: Camera preview in body (below appbar) ──
            Expanded(child: _buildCameraBody(pages)),

            // ── C5: Solid bottom controls panel ──
            _buildBottomPanel(pages),
          ],
        ),
      ),
    );
  }

  // ── C3: GDA-style AppBar matching home screen ──
  PreferredSizeWidget _buildGdaAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(62),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.navyDark,
          border: Border(
            bottom: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
            child: Row(children: [

              // Left: Close button
              GestureDetector(
                onTap: () {
                  ref.read(scannedPagesProvider.notifier).clear();
                  context.pop();
                },
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white, size: 18),
                ),
              ),

              const SizedBox(width: 10),

              // Center: Logo + Title
              Expanded(child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/gda_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text('GDA',
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 7, color: Colors.white,
                            fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('GDA Vault AI',
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                    Text('Scan Document',
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.55))),
                  ],
                ),
              ])),

              // Right: controls
              Row(children: [
                _AppBarIconBtn(
                  icon: _showGrid
                    ? Icons.grid_on_rounded
                    : Icons.grid_off_rounded,
                  onTap: () => setState(() => _showGrid = !_showGrid),
                  isActive: _showGrid,
                ),
                const SizedBox(width: 6),
                _AppBarIconBtn(
                  icon: _isFlashOn
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                  onTap: _toggleFlash,
                  isActive: _isFlashOn,
                ),
                const SizedBox(width: 6),
                _AppBarIconBtn(
                  icon: _isHighRes ? Icons.hd_rounded : Icons.sd_rounded,
                  onTap: _toggleResolution,
                  isActive: _isHighRes,
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Camera body with capture animation overlay ──
  Widget _buildCameraBody(List<ScannedPage> pages) {
    return Stack(children: [

      // Camera preview
      _buildCameraPreview(),

      // Grid overlay (optional)
      if (_showGrid)
        CustomPaint(
          size: Size.infinite,
          painter: _GridPainter(),
        ),

      // ── C6: Scan line shown ONLY during capture ──
      if (_showCaptureScan)
        AnimatedBuilder(
          animation: _captureScanAnim,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _CaptureScanPainter(
                progress: _captureScanAnim.value),
            );
          },
        ),

      // White flash on capture
      AnimatedBuilder(
        animation: _flashAnim,
        builder: (context, child) {
          if (_flashAnim.value == 0) return const SizedBox.shrink();
          return Container(
            color: Colors.white.withValues(alpha: _flashAnim.value * 0.5));
        },
      ),

      // Corner frame brackets (static, no animation)
      CustomPaint(
        size: Size.infinite,
        painter: _StaticFramePainter(showGrid: _showGrid),
      ),
    ]);
  }

  Widget _buildCameraPreview() {
    if (!_isCameraReady || _cameraController == null) {
      return Container(
        color: const Color(0xFF0A0F1E),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 36, height: 36,
                child: CircularProgressIndicator(
                  color: AppColors.gold, strokeWidth: 2.5)),
              const SizedBox(height: 14),
              Text('Initializing Camera...',
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 13, color: Colors.white70)),
            ],
          ),
        ),
      );
    }
    return SizedBox.expand(
      child: CameraPreview(_cameraController!),
    );
  }

  // ── C5: Solid bottom panel ──
  Widget _buildBottomPanel(List<ScannedPage> pages) {
    return Container(
      color: AppColors.navyDark,
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Mode selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['AUTO', 'MANUAL', 'WHITEBOARD', 'ID CARD']
                .map((mode) => _ModePill(mode: mode)).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Main capture row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // Pages count thumbnail (left)
              GestureDetector(
                onTap: pages.isNotEmpty ? _showPagesSheet : null,
                child: Stack(children: [
                  Container(
                    width: 52, height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: pages.isNotEmpty
                          ? AppColors.gold
                          : Colors.white.withValues(alpha: 0.2),
                        width: pages.isNotEmpty ? 1.8 : 1,
                      ),
                    ),
                    child: pages.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(pages.last.currentPath),
                            fit: BoxFit.cover,
                            width: 52, height: 68,
                          ),
                        )
                      : const Icon(Icons.description_outlined,
                          color: Colors.white24, size: 22),
                  ),
                  if (pages.isNotEmpty)
                    Positioned(
                      top: -4, right: -4,
                      child: Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle),
                        child: Center(
                          child: Text('${pages.length}',
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyDark)),
                        ),
                      ),
                    ),
                ]),
              ),

              // Capture button (center)
              GestureDetector(
                onTap: _capturePhoto,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 3),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: _isCapturing ? 56 : 66,
                      height: _isCapturing ? 56 : 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCapturing
                          ? AppColors.gold.withValues(alpha: 0.8)
                          : Colors.white,
                        boxShadow: [BoxShadow(
                          color: Colors.white.withValues(alpha: 0.25),
                          blurRadius: 10, spreadRadius: 2)],
                      ),
                      child: _isCapturing
                        ? const Center(child: SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                              color: AppColors.navyDark,
                              strokeWidth: 2.5)))
                        : null,
                    ),
                  ],
                ),
              ),

              // Review / Done button (right)
              GestureDetector(
                onTap: pages.isNotEmpty ? _proceedToReview : null,
                child: AnimatedOpacity(
                  opacity: pages.isNotEmpty ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: pages.isNotEmpty
                        ? AppColors.gdaGreen
                        : Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: pages.isNotEmpty
                          ? AppColors.gdaGreen
                          : Colors.white.withValues(alpha: 0.15)),
                      boxShadow: pages.isNotEmpty ? [BoxShadow(
                        color: AppColors.gdaGreen.withValues(alpha: 0.35),
                        blurRadius: 10, offset: const Offset(0,3))] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded,
                          color: Colors.white, size: 22),
                        const SizedBox(height: 2),
                        Text('Done',
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 9, color: Colors.white,
                            fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Page count label
          if (pages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${pages.length} page${pages.length > 1 ? 's' : ''} ready  ·  Tap Done to review',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.55)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Static frame brackets painter (no animation) ──
class _StaticFramePainter extends CustomPainter {
  final bool showGrid;
  const _StaticFramePainter({this.showGrid = false});

  @override
  void paint(Canvas canvas, Size size) {
    final fL = size.width  * 0.06;
    final fT = size.height * 0.06;
    final fR = size.width  * 0.94;
    final fB = size.height * 0.88;
    const cLen = 26.0;

    final paint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(fL, fT + cLen), Offset(fL, fT), paint);
    canvas.drawLine(Offset(fL, fT), Offset(fL + cLen, fT), paint);
    // Top-right
    canvas.drawLine(Offset(fR - cLen, fT), Offset(fR, fT), paint);
    canvas.drawLine(Offset(fR, fT), Offset(fR, fT + cLen), paint);
    // Bottom-left
    canvas.drawLine(Offset(fL, fB - cLen), Offset(fL, fB), paint);
    canvas.drawLine(Offset(fL, fB), Offset(fL + cLen, fB), paint);
    // Bottom-right
    canvas.drawLine(Offset(fR - cLen, fB), Offset(fR, fB), paint);
    canvas.drawLine(Offset(fR, fB), Offset(fR, fB - cLen), paint);

    // Thin frame border
    canvas.drawRect(
      Rect.fromLTRB(fL, fT, fR, fB),
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.2)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );

    if (showGrid) {
      final gp = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = 0.5;
      final fw = fR - fL;
      final fh = fB - fT;
      canvas.drawLine(Offset(fL + fw/3, fT), Offset(fL + fw/3, fB), gp);
      canvas.drawLine(Offset(fL + fw*2/3, fT), Offset(fL + fw*2/3, fB), gp);
      canvas.drawLine(Offset(fL, fT + fh/3), Offset(fR, fT + fh/3), gp);
      canvas.drawLine(Offset(fL, fT + fh*2/3), Offset(fR, fT + fh*2/3), gp);
    }
  }

  @override
  bool shouldRepaint(_StaticFramePainter old) =>
    old.showGrid != showGrid;
}

// ── Capture-only scan line painter ──
class _CaptureScanPainter extends CustomPainter {
  final double progress;
  const _CaptureScanPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final fT = size.height * 0.06;
    final fB = size.height * 0.88;
    final fL = size.width  * 0.06;
    final fR = size.width  * 0.94;
    final y = fT + (fB - fT) * progress;
    final lineW = fR - fL;

    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.gold.withValues(alpha: 0.35), Colors.transparent],
      ).createShader(Rect.fromLTWH(fL, y, lineW, 52));
    canvas.drawRect(Rect.fromLTWH(fL, y, lineW, 52), glowPaint);

    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.gold.withValues(alpha: 0.9),
          AppColors.gold,
          AppColors.gold.withValues(alpha: 0.9),
          Colors.transparent,
        ],
        stops: const [0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(fL, y, lineW, 2.5))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(fL, y), Offset(fR, y), linePaint);
  }

  @override
  bool shouldRepaint(_CaptureScanPainter old) =>
    old.progress != progress;
}

// ── Grid painter ──
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(size.width/3, 0),
      Offset(size.width/3, size.height), p);
    canvas.drawLine(Offset(size.width*2/3, 0),
      Offset(size.width*2/3, size.height), p);
    canvas.drawLine(Offset(0, size.height/3),
      Offset(size.width, size.height/3), p);
    canvas.drawLine(Offset(0, size.height*2/3),
      Offset(size.width, size.height*2/3), p);
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ── AppBar icon button ──
class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  const _AppBarIconBtn({
    
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
            ? AppColors.gold.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.08),
          border: isActive
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.2)
            : null,
        ),
        child: Icon(icon, size: 17,
          color: isActive ? AppColors.gold : Colors.white),
      ),
    );
  }
}

// ── Mode pill ──
class _ModePill extends StatefulWidget {
  final String mode;
  const _ModePill({required this.mode});

  @override
  State<_ModePill> createState() => _ModePillState();
}

class _ModePillState extends State<_ModePill> {
  bool _selected = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.mode == 'AUTO';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _selected = !_selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _selected
            ? AppColors.gold
            : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: _selected
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text(widget.mode,
          style: AppTextStyles.dmSans.copyWith(
            fontSize: 11,
            fontWeight: _selected ? FontWeight.bold : FontWeight.normal,
            color: _selected ? AppColors.navyDark : Colors.white,
          )),
      ),
    );
  }
}

// ── Scanned Pages Sheet ──
class _ScannedPagesSheet extends StatelessWidget {
  final List<ScannedPage> pages;
  final VoidCallback onDone;
  final Function(String) onDelete;

  const _ScannedPagesSheet({
    required this.pages,
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.charcoal.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2)),
        )),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Scanned (${pages.length})',
            style: AppTextStyles.playfairDisplay.copyWith(
              fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: onDone,
            child: Text('Review & Save →',
              style: AppTextStyles.dmSans.copyWith(color: AppColors.gold))),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pages.length,
            itemBuilder: (context, i) {
              final page = pages[i];
              return Stack(children: [
                Container(
                  width: 88, height: 118,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(page.currentPath), fit: BoxFit.cover),
                  ),
                ),
                Positioned(bottom: 4, left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.navyDark.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4)),
                    child: Text('p.${i+1}',
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 8, color: Colors.white)),
                  ),
                ),
                Positioned(top: -2, right: 8,
                  child: GestureDetector(
                    onTap: () => onDelete(page.id),
                    child: Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ]);
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add_a_photo, size: 16),
              label: const Text('Add More'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onDone,
              icon: const Icon(Icons.check_rounded, size: 16,
                color: AppColors.navyDark),
              label: Text('Review',
                style: AppTextStyles.dmSans.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDark)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ]),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ]),
    );
  }
}
