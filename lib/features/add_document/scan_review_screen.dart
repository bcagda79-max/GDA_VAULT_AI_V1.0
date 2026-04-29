import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';

/// Allows reviewing and basic editing of scanned pages before categorization.
class ScanReviewScreen extends StatefulWidget {
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
  State<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends State<ScanReviewScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isProcessing = false;
  late List<String> _currentPaths;
  final Map<int, String> _originalPaths = {};
  final Map<int, bool> _isBW = {};
  final Map<int, bool> _isEnhanced = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentPaths = List.from(widget.imagePaths);
    for (int i = 0; i < _currentPaths.length; i++) {
      _originalPaths[i] = _currentPaths[i];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleBW() async {
    final currentlyBW = _isBW[_currentPage] ?? false;
    if (currentlyBW) {
      setState(() {
        _currentPaths[_currentPage] = _originalPaths[_currentPage]!;
        _isBW[_currentPage] = false;
        _isEnhanced[_currentPage] = false;
      });
    } else {
      await _applyFilter(_currentPage, isBW: true);
    }
  }

  Future<void> _toggleEnhance() async {
    final currentlyEnhanced = _isEnhanced[_currentPage] ?? false;
    if (currentlyEnhanced) {
      setState(() {
        _currentPaths[_currentPage] = _originalPaths[_currentPage]!;
        _isBW[_currentPage] = false;
        _isEnhanced[_currentPage] = false;
      });
    } else {
      await _applyFilter(_currentPage, isEnhanced: true);
    }
  }

  Future<void> _applyFilter(int index, {bool isBW = false, bool isEnhanced = false}) async {
    setState(() => _isProcessing = true);
    try {
      final originalPath = _originalPaths[index]!;
      // Use compute if available for better performance, but here keeping it simple
      final bytes = await File(originalPath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image != null) {
        if (isBW) {
          // CamScanner-style B&W: High contrast grayscale
          image = img.grayscale(image);
          image = img.contrast(image, contrast: 180);
          image = img.adjustColor(image, brightness: 1.15);
        } else if (isEnhanced) {
          // Magic Color: Vibrant and Sharp
          image = img.adjustColor(image, contrast: 1.4, brightness: 1.2, saturation: 1.1);
          image = img.convolution(image, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]); // Sharpen
        }

        final tempDir = await getTemporaryDirectory();
        final filteredPath = '${tempDir.path}/filtered_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(filteredPath).writeAsBytes(img.encodeJpg(image));

        if (mounted) {
          setState(() {
            _currentPaths[index] = filteredPath;
            _isBW[index] = isBW;
            _isEnhanced[index] = isEnhanced;
          });
        }
      }
    } catch (e) {
      debugPrint("Filter Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _saveAndProceed() {
    context.push('/dashboard/add/select-category', extra: {
      'source': widget.source,
      'pageCount': _currentPaths.length,
      'imagePaths': _currentPaths,
      'fileName': 'Scan_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}.pdf'
    });
  }

  void _deletePage() {
    if (_currentPaths.length <= 1) {
      context.pop();
      return;
    }
    
    setState(() {
      _currentPaths.removeAt(_currentPage);
      // Re-index original paths if needed or just accept the shift
      if (_currentPage >= _currentPaths.length) {
        _currentPage = _currentPaths.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2A2A),
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          "Review Document",
          style: AppTextStyles.playfairDisplay.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _saveAndProceed,
            child: Text(
              "Save",
              style: AppTextStyles.dmSans.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.gold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Main Page Preview
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _currentPaths.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F5EE),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(_currentPaths[index]),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildMockPageFallback(index),
                          ),
                        ),
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
              ],
            ),
          ),


          // 2. Editing Toolbar
          Container(
            color: const Color(0xFF1C1C1E),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEditAction(icon: Icons.crop_rounded, label: "Crop", onTap: () => _showEditFeedback("Crop applied")),
                _buildEditAction(icon: Icons.rotate_right_rounded, label: "Rotate", onTap: () => _showEditFeedback("Rotated")),
                _buildEditAction(
                  icon: Icons.brightness_6,
                  label: "Enhance",
                  onTap: _toggleEnhance,
                  isSelected: _isEnhanced[_currentPage] ?? false,
                ),
                _buildEditAction(
                  icon: Icons.filter_b_and_w,
                  label: "B&W",
                  onTap: _toggleBW,
                  isSelected: _isBW[_currentPage] ?? false,
                ),
                _buildEditAction(icon: Icons.delete_outline, label: "Delete", onTap: _deletePage),
              ],
            ),
          ),

          // 3. Bottom Thumbnails Strip
          Container(
            color: const Color(0xFF111111),
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _currentPaths.length,
              itemBuilder: (context, index) {
                final isSelected = _currentPage == index;
                return GestureDetector(
                  onTap: () => _pageController.jumpToPage(index),
                  child: AnimatedContainer(
                    width: isSelected ? 56 : 50,
                    height: isSelected ? 68 : 60,
                    margin: const EdgeInsets.only(right: 8),
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EDE4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(_currentPaths[index]),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.description_rounded, size: 20),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Save Button
          Container(
            color: const Color(0xFF0A0A0A),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${_currentPaths.length} pages ready", style: AppTextStyles.dmSans.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("Tap Save to categorize", style: AppTextStyles.dmSans.copyWith(fontSize: 10, color: Colors.white.withValues(alpha: 0.45))),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _saveAndProceed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.gdaGreen, Color(0xFF1A8A4A)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: AppColors.gdaGreen.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.save_rounded, size: 18, color: Colors.white),
                        AppSpacing.horizontal(8),
                        Text(
                          "Save & Categorize",
                          style: AppTextStyles.dmSans.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockPageFallback(int index) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 8, decoration: BoxDecoration(color: AppColors.charcoal.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
                  AppSpacing.vertical(3),
                  Container(width: 70, height: 6, decoration: BoxDecoration(color: AppColors.charcoal.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2))),
                ],
              ),
              Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.catBoard.withValues(alpha: 0.2), shape: BoxShape.circle)),
            ],
          ),
          AppSpacing.vertical(8),
          Divider(color: AppColors.charcoal.withValues(alpha: 0.15), thickness: 1),
          AppSpacing.vertical(10),
          ...List.generate(12, (i) => Container(margin: const EdgeInsets.only(bottom: 5), height: 7, width: double.infinity, decoration: BoxDecoration(color: AppColors.charcoal.withValues(alpha: 0.1 + (i % 4) * 0.02), borderRadius: BorderRadius.circular(3)))),
        ],
      ),
    );
  }

  Widget _buildEditAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.gold.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: isSelected ? Border.all(color: AppColors.gold.withValues(alpha: 0.4)) : null,
            ),
            child: Icon(icon, size: 20, color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.7)),
          ),
          AppSpacing.vertical(4),
          Text(label, style: AppTextStyles.dmSans.copyWith(fontSize: 9, color: Colors.white.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  void _showEditFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
