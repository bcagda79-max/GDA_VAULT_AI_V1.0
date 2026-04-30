import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';

/// Real camera-based document scanner using device camera
class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  final List<String> _scannedImagePaths = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _captureDocument() async {
    if (_isCapturing || !_isCameraInitialized || _cameraController == null) {
      return;
    }

    try {
      setState(() => _isCapturing = true);

      final image = await _cameraController!.takePicture();

      String pathToAdd = image.path;
      try {
        final bytes = await File(image.path).readAsBytes();
        img.Image? decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final fixed = img.bakeOrientation(decoded);
          final tempDir = await getTemporaryDirectory();
          final outPath =
              '${tempDir.path}/capt_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await File(outPath).writeAsBytes(img.encodeJpg(fixed, quality: 95));
          pathToAdd = outPath;
        }
      } catch (e) {
        debugPrint('Capture orientation fix failed: $e');
      }

      if (mounted) {
        setState(() {
          _scannedImagePaths.add(pathToAdd);
          _isCapturing = false;
        });

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Page ${_scannedImagePaths.length} captured! Tap again for more',
            ),
            backgroundColor: AppColors.gdaGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFlash() async {
    try {
      if (_cameraController == null) return;
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (e) {
      // Flash not supported
    }
  }

  void _proceedToReview() {
    if (_scannedImagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture at least one page'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.push(
      '/dashboard/add/review',
      extra: {
        'pageCount': _scannedImagePaths.length,
        'source': 'camera',
        'imagePaths': List<String>.from(_scannedImagePaths),
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _isCameraInitialized) {
            final cameraController = _cameraController;
            if (cameraController == null) {
              return const SizedBox.shrink();
            }

            return Stack(
              children: [
                // Camera Preview
                CameraPreview(cameraController),

                // Top Toolbar
                _buildTopToolbar(),

                // Page Counter
                _buildPageCounter(),

                // Bottom Controls
                _buildBottomControls(),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.white),
                  AppSpacing.vertical(16),
                  Text(
                    'Camera Error',
                    style: AppTextStyles.playfairDisplay.copyWith(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  AppSpacing.vertical(8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                  AppSpacing.vertical(16),
                  Text(
                    'Initializing Camera...',
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTopToolbar() {
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
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
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
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              'Document Scanner',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: _toggleFlash,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  size: 20,
                  color: _isFlashOn ? AppColors.gold : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageCounter() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.navyDark.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Page ${_scannedImagePaths.length + 1}',
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_scannedImagePaths.isNotEmpty) ...[
              Text(
                '${_scannedImagePaths.length} page${_scannedImagePaths.length > 1 ? 's' : ''} scanned',
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              AppSpacing.vertical(16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Capture Button
                GestureDetector(
                  onTap: _isCapturing ? null : _captureDocument,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _isCapturing
                          ? LinearGradient(
                              colors: [
                                AppColors.gold.withValues(alpha: 0.5),
                                AppColors.gold.withValues(alpha: 0.5),
                              ],
                            )
                          : const LinearGradient(
                              colors: [AppColors.gold, Color(0xFFFAD94D)],
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isCapturing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                  ),
                ).animate().fadeIn(duration: 400.ms),

                // Done Button (if pages scanned)
                if (_scannedImagePaths.isNotEmpty)
                  GestureDetector(
                    onTap: _proceedToReview,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gdaGreen,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gdaGreen.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.white,
                          ),
                          AppSpacing.horizontal(6),
                          Text(
                            'Done',
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
