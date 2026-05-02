import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
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
  bool _showThumbnails = true;
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _hasInternet = true;
  String? _localPdfPath;
  String? _pdfUrl;
  String? _errorMessage;
  String _downloadStatus = '';
  double _downloadProgress = 0.0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    PdfViewerService.instance.recordRecentlyOpened(widget.document);
    _loadPdf();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _hasInternet = result.any((r) => r != ConnectivityResult.none);
      });
    }
  }

  Future<void> _loadPdf() async {
    setState(() => _isLoading = true);
    try {
      // Prioritize local file if it exists
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

      // If no local file, we must have internet to load from network
      if (!_hasInternet) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No internet connection and file not cached.';
          });
        }
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

  Future<void> _deleteDocument() async {
    final success = await PdfViewerService.instance.removeOfflineDocument(widget.document.storagePath);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File removed from offline storage')),
      );
      context.pop(); // Go back as the file is gone
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOfflineFile = _localPdfPath != null;

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
            if (!isOfflineFile && _hasInternet)
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
                if (value == 'view_file_info') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${widget.document.fileName} • ${widget.document.yearLabel}',
                      ),
                    ),
                  );
                } else if (value == 'delete_offline') {
                  _deleteDocument();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'view_file_info',
                  child: Text('View File Info'),
                ),
                if (isOfflineFile)
                  const PopupMenuItem<String>(
                    value: 'delete_offline',
                    child: Text('Delete Offline Copy', style: TextStyle(color: Colors.red)),
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
            if (!_isLoading && _totalPages > 0 && _hasInternet)
              _BottomAskAIButton(
                document: widget.document,
                bottomOffset: _isDownloading ? 110 : 14,
              ),
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

class _BottomAskAIButton extends StatelessWidget {
  final DocumentModel document;
  final double bottomOffset;

  const _BottomAskAIButton({
    required this.document,
    required this.bottomOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomOffset,
      child: SizedBox(
        height: 46,
        child: ElevatedButton.icon(
          onPressed: () => context.go(
            '/dashboard/chat',
            extra: {
              'documentId': document.id,
              'from': 'pdf_viewer',
              'categoryId': document.categoryId,
              'subCategoryId': document.subCategoryId,
              'year': document.yearStart.toString(),
            },
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navyDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.gdaGold.withValues(alpha: 0.5)),
            ),
            elevation: 8,
            shadowColor: AppColors.gdaGold.withValues(alpha: 0.25),
          ),
          icon: const Icon(Icons.auto_awesome, color: AppColors.gdaGold),
          label: Text(
            'Ask AI',
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
