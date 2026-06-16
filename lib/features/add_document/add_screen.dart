import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/services/document_upload_service.dart';
import 'package:gda_vault_ai/core/utils/pdf_utils.dart';
import 'package:gda_vault_ai/core/utils/responsive_app_bar.dart';
import 'package:gda_vault_ai/core/utils/file_transfer.dart';
import 'package:gda_vault_ai/providers/profile_provider.dart';

class AddScreen extends ConsumerWidget {
  const AddScreen({super.key});

  Future<void> _pickPDFFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (!context.mounted) return;

        if (file.size > DocumentUploadService.maxPdfUploadSizeBytes) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'PDF is too large. Maximum upload size is ${DocumentUploadService.maxPdfUploadSizeLabel}.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final int actualPageCount = await PdfUtils.getPageCount(file.path!);

        if (!context.mounted) return;

        FileTransfer.currentFileBytes = file.bytes;

        context.push(
          '/dashboard/add/select-category',
          extra: {
            'source': 'file',
            'fileName': file.name,
            'fileSize': file.size,
            'filePath': file.path,
            'fileBytes': file.bytes,
            'pageCount': actualPageCount,
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
    final isAdmin = ref.watch(isAdminProvider);

    if (!isAdmin) {
      return _buildNonAdminView(context, ref);
    }

    return _buildAdminView(context, ref);
  }

  Widget _buildNonAdminView(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPage = isDark ? const Color(0xFF0A0A0A) : AppTokens.lightBgPage;
    final bgSurface = isDark ? const Color(0xFF1C1C1C) : AppTokens.lightBgSurface;
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
    final textPrimary = isDark ? Colors.white : AppTokens.lightTextPrimary;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary = isDark ? Colors.white54 : AppTokens.lightTextSecondary.withValues(alpha: 0.6);
    final brandPrimary = isDark ? Colors.white : const Color(0xFF141414);

    // Get role from profileProvider if possible
    final profile = ref.watch(profileProvider);
    final userRole = profile.value?['role'];

    return Scaffold(
      backgroundColor: bgPage,
      appBar: _buildGlobalAppBar(context, "Add Document", null, showBack: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.lock_outline, size: 28, color: textTertiary),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Access Restricted",
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 280,
                child: Text(
                  "Only administrators can upload documents to the GDA Vault. Please contact your system administrator to request access.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings_outlined, size: 18, color: textTertiary),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Administrator Required",
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          "Role: ${userRole ?? 'Standard User'}",
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => context.go('/dashboard/home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: brandPrimary,
                  side: BorderSide(color: borderLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(double.infinity, 40),
                  textStyle: AppTextStyles.bodyMd.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text("Go to Dashboard"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGlobalAppBar(BuildContext context, String title, String? subtitle, {bool showBack = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF141414) : Colors.white;
    final textColor = isDark ? Colors.white : AppTokens.lightTextPrimary;
    final subtextColor = isDark ? const Color(0xFF8A8A8A) : AppTokens.lightTextSecondary;
    final iconColor = isDark ? Colors.white : AppTokens.lightTextPrimary;
    
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (showBack)
                  IconButton(
                    icon: Icon(Icons.arrow_back, size: 20, color: iconColor),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 10,
                            color: subtextColor,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 40), // Balance spacing
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminView(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPage = isDark ? const Color(0xFF0A0A0A) : AppTokens.lightBgPage;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgPage,
      appBar: _buildGlobalAppBar(context, "Add Document", null, showBack: false),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 860;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: isDesktop
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPageIntro(isDark),
                      const SizedBox(height: 24),
                      Text(
                        "CHOOSE METHOD",
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 11,
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildChooseFromDeviceCard(context, isDark),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildScanDocumentCard(context, isDark),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPageIntro(isDark),
                      const SizedBox(height: 24),
                      Text(
                        "CHOOSE METHOD",
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 11,
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildChooseFromDeviceCard(context, isDark),
                      const SizedBox(height: 12),
                      _buildScanDocumentCard(context, isDark),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildPageIntro(bool isDark) {
    final bgColor = isDark ? const Color(0xFF1C1C1C) : const Color(0xFF1B2E4B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF272727) : Colors.transparent, width: isDark ? 0.5 : 0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ADD NEW DOCUMENT",
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: const Color(0xFF4ADE80),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Add New Document",
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Scan physical documents or import PDF files",
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF8899B0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Center(
              child: Icon(
                Icons.upload_file_outlined,
                size: 22,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip(IconData icon, String label, bool isDark) {
    final bgPage = isDark ? const Color(0xFF0A0A0A) : AppTokens.lightBgPage;
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary = isDark ? Colors.white54 : AppTokens.lightTextSecondary.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgPage,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textTertiary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChooseFromDeviceCard(BuildContext context, bool isDark) {
    final bgSurface = isDark ? const Color(0xFF141414) : AppTokens.lightBgSurface;
    final brandSurface = isDark ? const Color(0xFF272727) : const Color(0xFFF3F4F6);
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
    final textPrimary = isDark ? Colors.white : AppTokens.lightTextPrimary;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final brandPrimary = isDark ? Colors.white : const Color(0xFF141414);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: brandSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
                ),
                child: Center(
                  child: Icon(Icons.upload_file_outlined, size: 20, color: brandPrimary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Choose from Device",
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Import existing PDF files from your device",
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: borderLight),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSpecChip(Icons.picture_as_pdf_outlined, "PDF Files Only", isDark),
                const SizedBox(width: 12),
                _buildSpecChip(Icons.storage_outlined, "Up to 200 MB", isDark),
              ],
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _pickPDFFile(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 46,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFFEBEBEB) : const Color(0xFF141414),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? const Color(0xFFEBEBEB).withValues(alpha: 0.1) : const Color(0xFF141414).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_outlined, size: 18, color: isDark ? const Color(0xFF141414) : Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    "Browse Files",
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF141414) : Colors.white,
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

  Widget _buildScanDocumentCard(BuildContext context, bool isDark) {
    final bgSurface = isDark ? const Color(0xFF141414) : AppTokens.lightBgSurface;
    final brandSurface = isDark ? const Color(0xFF272727) : const Color(0xFFF3F4F6);
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
    final textPrimary = isDark ? Colors.white : AppTokens.lightTextPrimary;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final brandPrimary = isDark ? Colors.white : const Color(0xFF141414);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: brandSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
                ),
                child: Center(
                  child: Icon(Icons.document_scanner_outlined, size: 20, color: brandPrimary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Scan Document",
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Use camera to scan physical documents",
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: borderLight),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSpecChip(Icons.crop_free, "Auto Edge Detect", isDark),
                const SizedBox(width: 12),
                _buildSpecChip(Icons.auto_fix_high_outlined, "Auto Enhance", isDark),
                const SizedBox(width: 12),
                _buildSpecChip(Icons.layers_outlined, "Multi-Page", isDark),
              ],
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => context.push('/dashboard/add/scanner'),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 46,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFFEBEBEB) : const Color(0xFF141414),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? const Color(0xFFEBEBEB).withValues(alpha: 0.1) : const Color(0xFF141414).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.document_scanner_outlined, size: 18, color: isDark ? const Color(0xFF141414) : Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    "Open Scanner",
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF141414) : Colors.white,
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
