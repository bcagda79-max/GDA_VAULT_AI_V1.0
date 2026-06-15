import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class ScanPdfPreviewScreen extends ConsumerStatefulWidget {
  final List<String> imagePaths;
  final String fileName;
  final String source;
  final int pageCount;

  const ScanPdfPreviewScreen({
    super.key,
    required this.imagePaths,
    required this.fileName,
    required this.source,
    required this.pageCount,
  });

  @override
  ConsumerState<ScanPdfPreviewScreen> createState() =>
      _ScanPdfPreviewScreenState();
}

class _ScanPdfPreviewScreenState extends ConsumerState<ScanPdfPreviewScreen> {
  late String _fileName;
  late PageController _pageController;
  int _currentPage = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fileName = widget.fileName;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showRenameDialog() {
    final ctrl = TextEditingController(text: _fileName.replaceAll('.pdf', ''));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTokens.lightBrandPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.drive_file_rename_outline_rounded,
              color: AppTokens.lightBrandPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Rename PDF',
              style: AppTextStyles.bodyMd.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter file name',
            hintStyle: TextStyle(color: Colors.white38),
            suffix: Text('.pdf', style: TextStyle(color: AppTokens.lightBrandPrimary)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTokens.lightBrandPrimary),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTokens.lightBrandPrimary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isNotEmpty) {
                setState(() => _fileName = '$t.pdf');
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Rename',
              style: TextStyle(
                color: AppTokens.lightBrandPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    final logoData = await rootBundle.load('assets/images/gda_logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    for (int i = 0; i < widget.imagePaths.length; i++) {
      final imgBytes = await File(widget.imagePaths[i]).readAsBytes();
      final pdfImage = pw.MemoryImage(imgBytes);

      pdf.addPage(
        pw.Page(
          margin: i == 0 ? const pw.EdgeInsets.all(32) : pw.EdgeInsets.zero,
          build: (pw.Context ctx) {
            if (i == 0) {
              return pw.Column(
                children: [
                  pw.Center(child: pw.Image(logoImage, width: 60, height: 60)),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Text(
                      'Galiyat Development Authority',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor(0.85, 0.72, 0.29),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Expanded(child: pw.Center(child: pw.Image(pdfImage))),
                ],
              );
            } else {
              return pw.Center(child: pw.Image(pdfImage));
            }
          },
        ),
      );
    }
    return pdf;
  }

  Future<void> _saveToDevice() async {
    setState(() => _isSaving = true);
    try {
      final pdf = await _generatePdf();
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
                    'PDF saved to device',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTokens.lightBrandPrimary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareAsPdf() async {
    setState(() => _isSaving = true);
    try {
      final pdf = await _generatePdf();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$_fileName');
      await file.writeAsBytes(await pdf.save());
      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'GDA Vault Document — $_fileName');
    } catch (e) {
      debugPrint('Share error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _proceedToCategories() {
    context.push(
      '/dashboard/add/select-category',
      extra: {
        'source': widget.source,
        'pageCount': widget.imagePaths.length,
        'imagePaths': widget.imagePaths,
        'fileName': _fileName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBot = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF2A2A2A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFF333333),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: widget.imagePaths.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Column(
                      children: [
                        Image.asset(
                          'assets/images/gda_logo.png',
                          width: 70,
                          height: 70,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Galiyat Development Authority',
                          style: AppTextStyles.headingMd.copyWith(
                            fontSize: 18,
                            color: AppTokens.lightBrandPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _showRenameDialog,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _fileName,
                                  style: AppTextStyles.bodyMd.copyWith(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.edit_rounded,
                                color: AppTokens.lightBrandPrimary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          height: 1,
                          color: Colors.white12,
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }

                  final imageIndex = i - 1;
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.file(
                        File(widget.imagePaths[imageIndex]),
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Container(
            color: AppTokens.lightBrandPrimary,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _proceedToCategories,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTokens.lightBrandPrimary, Color(0xFF1A3A6B)],
                        ),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: AppTokens.lightBrandPrimary.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTokens.lightBrandPrimary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTokens.lightBrandPrimary,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Done — Categorize',
                              style: AppTextStyles.bodyMd.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  AppBar _buildAppBar() {
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
      title: Text(
        'PDF Preview',
        style: AppTextStyles.headingMd.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        // Share
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
          onPressed: _shareAsPdf,
          tooltip: 'Share PDF',
        ),
        // Save to device
        GestureDetector(
          onTap: _isSaving ? null : _saveToDevice,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _isSaving
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppTokens.lightBrandPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isSaving
                    ? Colors.white12
                    : AppTokens.lightBrandPrimary.withValues(alpha: 0.4),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: AppTokens.lightBrandPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.save_alt_rounded,
                        size: 13,
                        color: AppTokens.lightBrandPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Save',
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 10,
                          color: AppTokens.lightBrandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
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
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

