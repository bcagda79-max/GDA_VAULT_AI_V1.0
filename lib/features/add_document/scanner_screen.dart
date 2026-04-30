import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/features/add_document/providers/scan_provider.dart';

/// A full-screen immersive scanner UI simulating a document scanner.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  bool _showFlashEffect = false;

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  Future<void> _initScanner() async {
    // Initialize camera
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_cameraController == null || !_isCameraInitialized || _isCapturing)
      return;

    setState(() {
      _isCapturing = true;
      _showFlashEffect = true;
    });
    HapticFeedback.mediumImpact();

    try {
      final XFile photo = await _cameraController!.takePicture();
      // Add to provider
      ref.read(scanImagesProvider.notifier).add(photo.path);

      setState(() {
        _isCapturing = false;
        _showFlashEffect = false;
      });

      _proceedToReview(); // Go to review immediately for now to make it feel "real"
    } catch (e) {
      debugPrint("Capture Error: $e");
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _showFlashEffect = false;
        });
      }
    }
  }

  void _proceedToReview() {
    final scannedPages = ref.read(scanImagesProvider);
    if (scannedPages.isEmpty) return;
    context.push(
      '/dashboard/add/review',
      extra: {
        'pageCount': scannedPages.length,
        'source': 'scanner',
        'imagePaths': scannedPages,
      },
    );
  }

  void _toggleFlash() {
    if (_cameraController == null) return;
    setState(() {
      _isFlashOn = !_isFlashOn;
      _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Preview
          _buildCameraMock(size),

          // 2. Flash Effect
          if (_showFlashEffect)
            Container(color: Colors.white.withValues(alpha: 0.8)),

          // 3. Camera UI Overlay
          Column(
            children: [
              // Top Bar
              _buildTopBar(context),

              const Spacer(),

              // Bottom UI Area
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Capture Controls
                    _buildCaptureControls(context, size),
                    AppSpacing.vertical(32),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
              Text(
                "Document Scanner",
                style: AppTextStyles.playfairDisplay.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: _isFlashOn ? AppColors.gold : Colors.white,
                ),
                onPressed: _toggleFlash,
              ),
              IconButton(
                icon: Icon(
                  Icons.hd_outlined,
                  color: _isHighRes ? AppColors.gold : Colors.white,
                ),
                onPressed: _toggleHighRes,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isHighRes = true;
  Future<void> _toggleHighRes() async {
    if (_cameraController == null) return;
    setState(() => _isHighRes = !_isHighRes);

    final currentFlash = _isFlashOn;
    await _cameraController!.dispose();

    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      _isHighRes ? ResolutionPreset.max : ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (currentFlash) {
      await _cameraController!.setFlashMode(FlashMode.torch);
    }

    if (mounted) setState(() {});
  }

  Widget _buildCaptureControls(BuildContext context, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Main Capture Button (Double Ring)
          GestureDetector(
            onTap: _startScan,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 4,
                    ),
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: _isCapturing
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.navyDark,
                            strokeWidth: 3,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),

          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  final scannedPages = ref.read(scanImagesProvider);
                  if (scannedPages.isNotEmpty) _showScannedPagesSheet();
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: ref.watch(scanImagesProvider).isEmpty
                      ? const Icon(
                          Icons.image_outlined,
                          color: Colors.white,
                          size: 24,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.file(
                            File(ref.watch(scanImagesProvider).last),
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraMock(Size size) {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        width: size.width,
        height: size.height,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    return ClipRect(
      child: SizedOverflowBox(
        size: size,
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.width * _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        ),
      ),
    );
  }

  void _showScannedPagesSheet() {
    final scannedPages = ref.read(scanImagesProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ScannedPagesSheet(
        scannedPages: scannedPages,
        onDone: _proceedToReview,
        onDelete: (index) {
          ref.read(scanImagesProvider.notifier).removeAt(index);
          if (ref.read(scanImagesProvider).isEmpty) Navigator.pop(context);
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

    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Scanned Pages (${scannedPages.length})",
                    style: AppTextStyles.playfairDisplay.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: onDone,
                    child: Text(
                      "Done →",
                      style: AppTextStyles.dmSans.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
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
                    final path = scannedPages[index];
                    return Container(
                      width: 80,
                      height: 110,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EDE4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // show real captured thumbnail if file exists
                          if (path.isNotEmpty && File(path).existsSync())
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(path),
                                width: 80,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Center(
                              child: Icon(
                                Icons.description_rounded,
                                size: 32,
                                color: AppColors.charcoal.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.navyDark.withValues(
                                  alpha: 0.7,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "p.${index + 1}",
                                style: AppTextStyles.dmSans.copyWith(
                                  fontSize: 8,
                                  color: Colors.white,
                                ),
                              ),
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
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo,
                            color: AppColors.gold,
                            size: 18,
                          ),
                          AppSpacing.horizontal(8),
                          Text(
                            "Add More",
                            style: AppTextStyles.dmSans.copyWith(
                              color: AppColors.gold,
                            ),
                          ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            color: AppColors.navyDark,
                            size: 18,
                          ),
                          AppSpacing.horizontal(8),
                          Text(
                            "Review & Save",
                            style: AppTextStyles.dmSans.copyWith(
                              color: AppColors.navyDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
