// lib/features/categories/pdf_viewer_screen.dart


import 'dart:io';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/models/document_model.dart';

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
                "${widget.document.pageCount} pages · ${widget.document.yearLabel}",
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
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.view_sidebar_rounded, color: Colors.white),
              onPressed: () {
                setState(() {
                  _showThumbnails = !_showThumbnails;
                });
              },
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
                  value: 'add_to_favourites',
                  child: Text('Add to Favourites'),
                ),
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
            if (File(widget.document.filePath).existsSync() && widget.document.filePath.toLowerCase().endsWith('.pdf'))
              SfPdfViewer.file(
                File(widget.document.filePath),
                canShowScrollHead: false,
                canShowScrollStatus: false,
                pageSpacing: 4,
              )
            else
              Row(
                children: [
                  _ThumbnailRail(
                    showThumbnails: _showThumbnails,
                    pageCount: widget.document.pageCount,
                    currentPage: _currentPage,
                    categoryColor: widget.categoryColor,
                    onPageSelected: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                  ),
                  Expanded(
                    child: _MainPdfMockArea(
                      document: widget.document,
                      currentPage: _currentPage,
                      categoryColor: widget.categoryColor,
                    ),
                  ),
                ],
              ),
            if (!File(widget.document.filePath).existsSync() || !widget.document.filePath.toLowerCase().endsWith('.pdf'))
              _BottomPageControls(
                currentPage: _currentPage,
                pageCount: widget.document.pageCount,
                categoryColor: widget.categoryColor,
                onPrevious: () {
                  if (_currentPage > 1) {
                    setState(() => _currentPage--);
                  }
                },
                onNext: () {
                  if (_currentPage < widget.document.pageCount) {
                    setState(() => _currentPage++);
                  }
                },
              ),
            _FloatingAskAIButton(documentId: widget.document.id),
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
                  "$pageNum",
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

class _MainPdfMockArea extends StatelessWidget {
  final DocumentModel document;
  final int currentPage;
  final Color categoryColor;

  const _MainPdfMockArea({
    required this.document,
    required this.currentPage,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 72),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GALIYAT DEVELOPMENT AUTHORITY",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      "ABBOTTABAD, KPK, PAKISTAN",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 7,
                        color: AppColors.charcoal.withValues(alpha: 0.5),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset(
                    'assets/images/gda_logo.png',
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.gavel_rounded,
                        size: 20,
                        color: categoryColor,
                      );
                    },
                  ),
                ),
              ],
            ),
            Divider(height: 16, color: categoryColor, thickness: 1.5),
            AppSpacing.vertical(16),
            Center(
              child: Column(
                children: [
                  Text(
                    document.fileName.replaceAll('.pdf', ''),
                    style: AppTextStyles.playfairDisplay.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                    ),
                  ),
                  AppSpacing.vertical(4),
                  Text(
                    document.yearLabel,
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 11,
                      color: AppColors.charcoal.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vertical(20),
            _buildMockTextLine(widthFactor: 1.0, opacity: 0.15),
            AppSpacing.vertical(6),
            _buildMockTextLine(widthFactor: 0.9, opacity: 0.12),
            AppSpacing.vertical(6),
            _buildMockTextLine(widthFactor: 0.95, opacity: 0.13),
            AppSpacing.vertical(12),
            _buildMockTextLine(widthFactor: 0.85, opacity: 0.1),
            AppSpacing.vertical(6),
            _buildMockTextLine(widthFactor: 1.0, opacity: 0.12),
            AppSpacing.vertical(6),
            _buildMockTextLine(widthFactor: 0.7, opacity: 0.1),
            AppSpacing.vertical(16),
            _buildMockTextLine(widthFactor: 0.95, opacity: 0.12),
            AppSpacing.vertical(6),
            _buildMockTextLine(widthFactor: 0.8, opacity: 0.1),
            AppSpacing.vertical(6),
            _buildMockTextLine(widthFactor: 1.0, opacity: 0.13),
            const Spacer(),
            const Divider(),
            AppSpacing.vertical(8),
            Center(
              child: Text(
                "Page $currentPage of ${document.pageCount}",
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 9,
                  color: AppColors.charcoal.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockTextLine({
    required double widthFactor,
    required double opacity,
  }) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.charcoal.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        alignment: Alignment.centerLeft,
        child: Container(color: AppColors.charcoal.withValues(alpha: opacity)),
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
              label: "Previous",
              enabled: currentPage > 1,
              onTap: onPrevious,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$currentPage / $pageCount",
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
                    widthFactor: currentPage / pageCount,
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
              label: "Next",
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
