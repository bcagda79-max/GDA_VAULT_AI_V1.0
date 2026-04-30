// ignore_for_file: prefer_final_fields, unused_field, unused_element
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/services/pdf_viewer_service.dart';
import 'package:gda_vault_ai/models/document_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  final DocumentModel document;
  final Color categoryColor;
  final String categoryName;

  const PdfViewerScreen({
    super.key,
    required this.document,
    required this.categoryColor,
    required this.categoryName,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int _currentPage = 1;
  bool _showThumbnails = true;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _localPdfPath;
  String? _pdfUrl;
  String? _errorMessage;
  String _downloadStatus = '';
  double _downloadProgress = 0.0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    PdfViewerService.instance.recordRecentlyOpened(widget.document);
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() => _isLoading = true);
    try {
      if (widget.document.isLocalPath &&
          await File(widget.document.storagePath).exists()) {
        if (!mounted) return;
        setState(() {
          _localPdfPath = widget.document.storagePath;
          _isLoading = false;
        });
        return;
      }

      final localPath = await PdfViewerService.instance.getLocalPdfPath(
        widget.document.storagePath,
        widget.document.fileName,
      );

      if (localPath != null && mounted) {
        setState(() {
          _localPdfPath = localPath.path;
          _isLoading = false;
        });
        return;
      }

      final url = await PdfViewerService.instance.getSignedUrl(
        widget.document.storagePath,
      );
      if (mounted) {
        setState(() {
          _pdfUrl = url;
          _isLoading = false;
          _errorMessage = url == null ? 'Failed to load document' : null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load document'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadOffline() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadStatus = 'Starting download...';
      _downloadProgress = 0.05;
    });

    final file = await PdfViewerService.instance.downloadDocument(
      widget.document,
      onProgress: (progress, status) {
        if (!mounted) return;
        setState(() {
          _downloadProgress = progress;
          _downloadStatus = status;
        });
      },
    );

    if (!mounted) return;
    setState(() {
      _isDownloading = false;
    });

    if (file != null) {
      setState(() => _localPdfPath = file.path);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved for offline access')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF2C2C2C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1C1C2E),
          leading: const BackButton(color: Colors.white),
          title: Column(
            children: [
              Text(
                widget.document.fileName,
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 13,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${widget.document.pageCount ?? 0} pages · ${widget.document.yearLabel}',
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              onPressed: _isDownloading ? null : _downloadOffline,
              tooltip: 'Download offline',
            ),
            IconButton(
              icon: const Icon(Icons.view_sidebar_rounded, color: Colors.white),
              onPressed: () =>
                  setState(() => _showThumbnails = !_showThumbnails),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'ask_ai') {
                  context.push(
                    '/chat',
                    extra: {
                      'documentId': widget.document.id,
                      'from': 'pdf_viewer',
                    },
                  );
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'view_file_info',
                  child: Text('View File Info'),
                ),
                const PopupMenuItem<String>(
                  value: 'ask_ai',
                  child: Text('Ask AI about this document'),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
            else if (_localPdfPath != null)
              SfPdfViewer.file(
                File(_localPdfPath!),
                canShowScrollHead: false,
                canShowScrollStatus: false,
                pageSpacing: 4,
                onDocumentLoaded: (details) {
                  if (mounted) {
                    setState(() => _totalPages = details.document.pages.count);
                  }
                },
              )
            else if (_pdfUrl != null)
              SfPdfViewer.network(
                _pdfUrl!,
                canShowScrollHead: false,
                canShowScrollStatus: false,
                pageSpacing: 4,
                onDocumentLoaded: (details) {
                  if (mounted) {
                    setState(() => _totalPages = details.document.pages.count);
                  }
                },
              )
            else
              Center(
                child: Text(
                  _errorMessage ?? 'Failed to load document',
                  style: AppTextStyles.dmSans.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            if (!_isLoading && _totalPages > 0)
              _FloatingAskAIButton(documentId: widget.document.id),
            if (_isDownloading)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _downloadStatus,
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            minHeight: 5,
                            backgroundColor: AppColors.divider,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.gold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(_downloadProgress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 11,
                            color: AppColors.charcoal.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailRail extends StatelessWidget {
  final bool showThumbnails;
  final int pageCount;
  final int currentPage;
  final Color categoryColor;
  final ValueChanged<int> onPageSelected;

  const _ThumbnailRail({
    required this.showThumbnails,
    required this.pageCount,
    required this.currentPage,
    required this.categoryColor,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: showThumbnails ? 44 : 0,
      color: const Color(0xFF1A1A1A),
      child: ListView.builder(
        itemCount: pageCount,
        itemBuilder: (context, index) {
          final pageNum = index + 1;
          final isSelected = pageNum == currentPage;
          return GestureDetector(
            onTap: () => onPageSelected(pageNum),
            child: Container(
              height: 48,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
                border: isSelected
                    ? Border.all(color: categoryColor, width: 1.5)
                    : null,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Center(
                child: Text(
                  '$pageNum',
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 8,
                    color: isSelected
                        ? Colors.black
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BottomPageControls extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final Color categoryColor;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _BottomPageControls({
    required this.currentPage,
    required this.pageCount,
    required this.categoryColor,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E).withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavButton(
              icon: Icons.chevron_left_rounded,
              label: 'Previous',
              enabled: currentPage > 1,
              onTap: onPrevious,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$currentPage / $pageCount',
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                AppSpacing.vertical(4),
                Container(
                  width: 120,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: pageCount == 0 ? 0 : currentPage / pageCount,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _NavButton(
              icon: Icons.chevron_right_rounded,
              label: 'Next',
              enabled: currentPage < pageCount,
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: Colors.white),
            Text(
              label,
              style: AppTextStyles.dmSans.copyWith(
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

class _FloatingAskAIButton extends StatelessWidget {
  final String documentId;
  const _FloatingAskAIButton({required this.documentId});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      right: 16,
      child: GestureDetector(
        onTap: () => context.push(
          '/chat',
          extra: {'documentId': documentId, 'from': 'pdf_viewer'},
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navyDark, Color(0xFF1A3A6B)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.gdaGold.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gdaGold.withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.gdaGold,
              ),
              AppSpacing.horizontal(6),
              Text(
                "Ask AI",
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
