import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gda_vault_ai/features/add_document/providers/scan_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';

/// Modal popup for adding new documents with 2 quick options
class AddDocumentModal extends ConsumerWidget {
  const AddDocumentModal({super.key});

  Future<void> _pickPDFFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (!context.mounted) return;

        // Close modal first
        Navigator.pop(context);

        // Navigate to category selector with actual file data
        context.push(
          '/dashboard/add/select-category',
          extra: {
            'source': 'file',
            'fileName': file.name,
            'fileSize': file.size,
            'filePath': file.path,
            'pageCount': 45,
          },
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add Document",
                          style: AppTextStyles.playfairDisplay.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.charcoal,
                          ),
                        ),
                        AppSpacing.vertical(2),
                        Text(
                          "Choose method",
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 11,
                            color: AppColors.charcoal.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.charcoal.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vertical(24),

                // Scan Option
                _buildOptionCard(
                      context: context,
                      isDark: isDark,
                      icon: Icons.document_scanner_rounded,
                      title: "Scan Document",
                      subtitle: "Use camera to scan physical documents",
                      badge: "RECOMMENDED",
                      onTap: () {
                        ref.read(scanImagesProvider.notifier).clear();
                        Navigator.pop(context);
                        context.push('/dashboard/add/camera-scanner');
                      },
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05, end: 0),
                AppSpacing.vertical(12),

                // File Picker Option
                _buildOptionCard(
                      context: context,
                      isDark: isDark,
                      icon: Icons.upload_file_rounded,
                      title: "Choose from Device",
                      subtitle: "Import existing PDF files",
                      onTap: () => _pickPDFFile(context),
                    )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.05, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDark.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: badge != null
                      ? const LinearGradient(
                          colors: [AppColors.catBoard, Color(0xFF1A3A6B)],
                        )
                      : const LinearGradient(
                          colors: [AppColors.gdaGreen, Color(0xFF1A8A4A)],
                        ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (badge != null
                                  ? AppColors.catBoard
                                  : AppColors.gdaGreen)
                              .withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 22, color: Colors.white),
              ),
              AppSpacing.horizontal(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.charcoal,
                          ),
                        ),
                        if (badge != null) ...[
                          AppSpacing.horizontal(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gdaGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gdaGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    AppSpacing.vertical(4),
                    Text(
                      subtitle,
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 11,
                        color: AppColors.charcoal.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.charcoal.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
