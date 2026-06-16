import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/services/document_upload_service.dart';
import 'package:gda_vault_ai/core/services/api_service.dart';
import 'package:gda_vault_ai/core/utils/file_transfer.dart';
import 'package:gda_vault_ai/models/category_model.dart';

class CategorySelectorScreen extends StatefulWidget {
  final String source;
  final int pageCount;
  final String fileName;
  final int? fileSize;
  final List<String> imagePaths;
  final String? filePath;
  final Uint8List? fileBytes;

  const CategorySelectorScreen({
    super.key,
    required this.source,
    required this.pageCount,
    required this.fileName,
    this.fileSize,
    this.imagePaths = const [],
    this.filePath,
    this.fileBytes,
  });

  @override
  State<CategorySelectorScreen> createState() => _CategorySelectorScreenState();
}

class _CategorySelectorScreenState extends State<CategorySelectorScreen> {
  final _api = ApiService.instance;
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  int _currentStep = 0;
  String? _selectedCategoryId;
  String? _selectedSubId;
  bool _isYearMode = true;

  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  double? _rawUploadFraction;
  int? _bytesSent;
  int? _totalBytes;
  String _uploadStatus = 'Preparing...';
  String? _error;
  List<CategoryModel> _categories = const [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.fileName;
    _loadCategories();
  }

  @override
  void dispose() {
    _yearController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rows = await _api.getAllCategories();
      final categories = rows.map(CategoryModel.fromMap).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load categories'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  CategoryModel? get _selectedCategory {
    final id = _selectedSubId ?? _selectedCategoryId;
    if (id == null) return null;
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  List<CategoryModel> get _topCategories =>
      _categories.where((c) => c.parentId == null).toList();

  List<CategoryModel> _childrenOf(String parentId) {
    return _categories.where((c) => c.parentId == parentId).toList();
  }

  bool get _selectedCategoryHasChildren {
    final selected = _selectedCategoryId == null
        ? null
        : _categories.where((c) => c.id == _selectedCategoryId).toList();
    if (selected == null || selected.isEmpty) return false;
    return _categories.any((c) => c.parentId == selected.first.id);
  }

  String get _finalYearLabel {
    if (_isYearMode) return _yearController.text.trim();
    return 'N/A';
  }

  String get _finalDocumentName {
    if (!_isYearMode && _nameController.text.trim().isNotEmpty) {
      return _nameController.text.trim();
    }
    return widget.fileName;
  }

  Future<void> _uploadDocument() async {
    final category = _selectedCategory;
    if (category == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _rawUploadFraction = null;
      _bytesSent = null;
      _totalBytes = null;
      _uploadStatus = 'Preparing...';
    });

    try {
      final yearStart =
          _isYearMode ? (int.tryParse(_yearController.text.trim()) ?? DateTime.now().year) : DateTime.now().year;
      final mainCategoryId = category.parentId ?? category.id;
      final subCategoryId = category.parentId != null ? category.id : null;
      final docName = _finalDocumentName;

      UploadResult result;
      if (widget.source == 'scanner') {
        result = await DocumentUploadService.instance.uploadScannedImages(
          imagePaths: widget.imagePaths,
          category: mainCategoryId,
          subCategory: subCategoryId,
          categoryStoragePath: category.storagePath,
          year: yearStart,
          fileName: docName,
          onProgress: (phase, progress, {bytesSent, totalBytes}) {
            if (!mounted) return;
            setState(() {
              _uploadStatus = phase;
              _bytesSent = bytesSent;
              _totalBytes = totalBytes;
              if (phase.toLowerCase().contains('upload')) {
                _rawUploadFraction = progress;
                _uploadProgress = 0.3 + (progress * 0.45);
              } else {
                _rawUploadFraction = null;
                _uploadProgress = progress;
              }
            });
          },
        );
      } else {
        if (!kIsWeb && (widget.filePath == null || widget.filePath!.isEmpty)) {
          throw StateError('Missing file path for imported PDF');
        }
        final pdfFile = kIsWeb ? File('') : File(widget.filePath!);
        result = await DocumentUploadService.instance.uploadPdfFile(
          pdfFile: pdfFile,
          category: mainCategoryId,
          subCategory: subCategoryId,
          categoryStoragePath: category.storagePath,
          year: yearStart,
          fileName: docName,
          pageCount: widget.pageCount,
          fileSizeBytes: widget.fileSize,
          fileBytes: widget.fileBytes ?? FileTransfer.currentFileBytes,
          onProgress: (phase, progress, {bytesSent, totalBytes}) {
            if (!mounted) return;
            setState(() {
              _uploadStatus = phase;
              _bytesSent = bytesSent;
              _totalBytes = totalBytes;

              if (phase.toLowerCase().contains('upload')) {
                _rawUploadFraction = progress;
                _uploadProgress = 0.3 + (progress * 0.45);
              } else {
                _rawUploadFraction = null;
                _uploadProgress = progress;
              }
            });
          },
        );
      }

      if (!mounted) return;
      setState(() => _isUploading = false);
      if (result.success) {
        final recordedPageCount =
            result.record != null && result.record?['page_count'] != null
            ? (result.record!['page_count'] as int)
            : widget.pageCount;
        _showSuccessSheet(result, recordedPageCount);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload failed: ${result.errorMessage ?? 'Unknown error'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSheet(UploadResult result, int pageCount) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SuccessBottomSheet(
        categoryName: _selectedCategory?.name ?? '',
        categoryColor: _selectedCategory?.color ?? AppTokens.lightBrandPrimary,
        finalYearLabel: _finalYearLabel,
        pageCount: pageCount,
        onView: () async {
          Navigator.pop(ctx);
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;

          final mainCategory = _selectedCategory?.parentId != null
              ? _categories.firstWhere(
                  (c) => c.id == _selectedCategory!.parentId,
                  orElse: () => _selectedCategory!,
                )
              : _selectedCategory!;

          context.go(
            '/categories/sub/${mainCategory.id}/years',
            extra: {
              'categoryName': mainCategory.name,
              'subCategoryName': _selectedCategory?.parentId != null
                  ? _selectedCategory?.name
                  : null,
              'categoryColor': mainCategory.color,
              'yearFrom': _selectedCategory?.yearFrom ?? 1961,
              'yearTo': _selectedCategory?.yearTo,
              'subCategoryId': _selectedCategory?.id,
            },
          );
        },
        onHome: () {
          Navigator.pop(ctx);
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  void _showAddMainCategoryDialog() {
    final TextEditingController newCatCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgSurface = isDark ? const Color(0xFF1C1C1C) : AppTokens.lightBgSurface;
        final bgPage = isDark ? const Color(0xFF0A0A0A) : AppTokens.lightBgPage;
        final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
        final textPrimary = isDark ? Colors.white : AppTokens.lightTextPrimary;
        final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
        final brandPrimary = isDark ? Colors.white : const Color(0xFF141414);

        return AlertDialog(
          backgroundColor: bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.all(20),
          titlePadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add Main Category",
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Create a new top-level category",
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "NAME",
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: newCatCtrl,
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 14,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: "e.g. Finance & Accounting",
                  hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderLight, width: isDark ? 0.5 : 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderLight, width: isDark ? 0.5 : 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: brandPrimary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  filled: true,
                  fillColor: bgPage,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondary,
                        side: BorderSide(color: borderLight, width: isDark ? 0.5 : 1.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(0, 42),
                        textStyle: AppTextStyles.bodyMd.copyWith(fontSize: 13),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = newCatCtrl.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(ctx);
                        
                        setState(() => _isLoading = true);
                        try {
                          await _api.createCategory(
                            name: name,
                            storagePath: name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), ''),
                            colorHex: '#1D5FD1', // Default brand primary
                            iconName: 'folder_rounded',
                          );
                          await _loadCategories();
                        } catch (e) {
                          setState(() => _isLoading = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add main category: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(0, 42),
                        textStyle: AppTextStyles.bodyMd.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      child: const Text("Add"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddSubCategoryDialog(CategoryModel parent) {
    final TextEditingController newSubCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgSurface = isDark ? const Color(0xFF1C1C1C) : AppTokens.lightBgSurface;
        final bgPage = isDark ? const Color(0xFF0A0A0A) : AppTokens.lightBgPage;
        final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
        final textPrimary = isDark ? Colors.white : AppTokens.lightTextPrimary;
        final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
        final brandPrimary = isDark ? Colors.white : const Color(0xFF141414);

        return AlertDialog(
          backgroundColor: bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.all(20),
          titlePadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add Sub-Category",
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Create a new sub-category under ${parent.name}",
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "NAME",
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: newSubCtrl,
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 14,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: "e.g. Board Minutes 2000-2010",
                  hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderLight, width: isDark ? 0.5 : 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderLight, width: isDark ? 0.5 : 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: brandPrimary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  filled: true,
                  fillColor: bgPage,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondary,
                        side: BorderSide(color: borderLight, width: isDark ? 0.5 : 1.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(0, 42),
                        textStyle: AppTextStyles.bodyMd.copyWith(fontSize: 13),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = newSubCtrl.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(ctx);
                        
                        setState(() => _isLoading = true);
                        try {
                          await _api.createSubCategory(
                            name: name,
                            parentId: parent.id,
                            storagePath: '${parent.storagePath}/${name.toLowerCase().replaceAll(' ', '_')}',
                            colorHex: '#${parent.color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
                            iconName: 'folder_rounded',
                          );
                          await _loadCategories();
                        } catch (e) {
                          setState(() => _isLoading = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add sub-category: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(0, 42),
                        textStyle: AppTextStyles.bodyMd.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      child: const Text("Add"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPage = isDark ? const Color(0xFF0A0A0A) : AppTokens.lightBgPage;

    return Scaffold(
      backgroundColor: bgPage,
      appBar: _buildSharedHeader(),
      body: Column(
        children: [
          _buildStepProgressBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 860;
                final content = AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentStep(isDark),
                );

                if (isDesktop) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        color: isDark ? const Color(0xFF141414) : AppTokens.lightBgSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight,
                            width: isDark ? 0.5 : 1.0,
                          ),
                        ),
                        elevation: isDark ? 0 : 2,
                        child: content,
                      ),
                    ),
                  );
                }

                return content;
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSharedHeader() {
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
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 20, color: iconColor),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Save Document",
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "Step ${_currentStep + 1} of 3",
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 10,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepProgressBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF141414) : Colors.white;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(bottom: BorderSide(color: Color(0xFF111111), width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(3, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          final label = ['Category', 'Year', 'Upload'][index];

          Widget iconWidget;
          if (isCompleted) {
            iconWidget: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 11, color: Colors.white),
            );
          } else if (isCurrent) {
            iconWidget: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Center(
                child: Text('${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black)),
              ),
            );
          } else {
            iconWidget: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3D5070)),
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Center(
                child: Text('${index + 1}', style: const TextStyle(fontSize: 11, color: Color(0xFF3D5070))),
              ),
            );
          }

          final stepWidget = Row(
            children: [
              if (isCompleted)
                Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 11, color: Colors.white),
                )
              else if (isCurrent)
                Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black)),
                  ),
                )
              else
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF3D5070)),
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Text('${index + 1}', style: const TextStyle(fontSize: 11, color: Color(0xFF3D5070))),
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isCompleted || isCurrent ? Colors.white : const Color(0xFF3D5070),
                ),
              ),
            ],
          );

          if (index < 2) {
            return Expanded(
              child: Row(
                children: [
                  stepWidget,
                  Expanded(
                    child: Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF111111),
                    ),
                  ),
                ],
              ),
            );
          }
          return stepWidget;
        }),
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    switch (_currentStep) {
      case 0: return _buildStep1(isDark);
      case 1: return _buildStep2(isDark);
      case 2: return _buildStep3(isDark);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTokens.lightBrandPrimary));
    }

    final bgSurface = isDark ? const Color(0xFF1C1C1C) : AppTokens.lightBgSurface;
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
    final textPrimary = isDark ? Colors.white : AppTokens.lightTextPrimary;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;

    final sizeStr = widget.fileSize != null
        ? '${(widget.fileSize! / 1048576).toStringAsFixed(1)} MB'
        : '${widget.pageCount} pages';

    final categorySelected = _selectedCategory != null &&
        (!_selectedCategoryHasChildren || _selectedSubId != null);

    return Column(
      key: const ValueKey('step1'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE4E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFFDC2626)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.fileName,
                              style: AppTextStyles.bodyMd.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            Text(sizeStr, style: AppTextStyles.bodyMd.copyWith(fontSize: 11, color: textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFD1FAE5)),
                        ),
                        child: const Text("Ready", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "MAIN CATEGORIES",
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    letterSpacing: 1.0, color: textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _buildCategoryItem(_topCategories[index], isDark),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _showAddMainCategoryDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTokens.lightBrandPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 18, color: AppTokens.lightBrandPrimary),
                        const SizedBox(width: 8),
                        Text(
                          "Add Main Category",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTokens.lightBrandPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: bgSurface,
          child: InkWell(
            onTap: categorySelected ? () => setState(() => _currentStep = 1) : null,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: categorySelected ? AppTokens.lightBrandPrimary : borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  "Continue",
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: categorySelected ? Colors.white : textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(CategoryModel category, bool isDark) {
    final isSelected = _selectedCategoryId == category.id;
    final children = _childrenOf(category.id);
    final hasSubCategories = children.isNotEmpty;

    final bgSurface = isDark ? const Color(0xFF1C1C1C) : AppTokens.lightBgSurface;
    final bgPage = isDark ? const Color(0xFF0A0A0A) : AppTokens.lightBgPage;
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
    final brandPrimary = isDark ? Colors.white : const Color(0xFF141414);
    final brandSurface = brandPrimary.withValues(alpha: 0.08);
    final textPrimary = isDark ? Colors.white : AppTokens.lightTextPrimary;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() {
            _selectedCategoryId = category.id;
            _selectedSubId = null;
          }),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? brandSurface : bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? brandPrimary : borderLight,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? brandSurface : bgPage,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? brandPrimary : borderLight),
                  ),
                  child: Center(
                    child: Icon(category.iconData, size: 16, color: isSelected ? brandPrimary : textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category.name,
                            style: AppTextStyles.bodyMd.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                          if (hasSubCategories)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: bgPage,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
                              ),
                              child: Text(
                                "${children.length} sub",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textSecondary),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${category.docCount} docs · All years",
                        style: AppTextStyles.bodyMd.copyWith(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns: isSelected ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.chevron_right, size: 18, color: isSelected ? brandPrimary : textSecondary.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ),
        if (isSelected)
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: _buildSubCategoryExpansion(category, children, isDark),
            ),
          ),
      ],
    );
  }

  Widget _buildSubCategoryExpansion(CategoryModel parent, List<CategoryModel> children, bool isDark) {
    final hasSubCategories = children.isNotEmpty;
    final bgSurface = isDark ? const Color(0xFF1C1C1C) : AppTokens.lightBgSurface;
    final bgPage = isDark ? const Color(0xFF0A0A0A) : AppTokens.lightBgPage;
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
    final borderMedium = isDark ? const Color(0xFF3D5070) : AppTokens.lightBorderLight;
    final brandPrimary = isDark ? Colors.white : const Color(0xFF141414);
    final brandSurface = brandPrimary.withValues(alpha: 0.08);
    final textPrimary = isDark ? Colors.white : AppTokens.lightTextPrimary;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;

    if (!hasSubCategories) {
      return Container(
        margin: const EdgeInsets.only(top: 6, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgPage,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: textSecondary.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(
                  "No sub-categories. File will be saved directly.",
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showAddSubCategoryDialog(parent),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 13, color: brandPrimary),
                  const SizedBox(width: 6),
                  Text("Add sub-category", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: brandPrimary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 6, left: 48),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: brandPrimary, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 6),
            child: Text(
              "SUB-CATEGORIES",
              style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.8,
                color: const Color(0xFF3D5070),
              ),
            ),
          ),
          ...children.map((sub) {
            final isSelectedSub = _selectedSubId == sub.id;
            return InkWell(
              onTap: () => setState(() => _selectedSubId = sub.id),
              child: Container(
                margin: const EdgeInsets.only(left: 12, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelectedSub ? brandSurface : bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelectedSub ? brandPrimary : borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: isSelectedSub ? brandSurface : bgPage,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isSelectedSub ? brandPrimary : borderLight),
                      ),
                      child: Center(
                        child: Icon(sub.iconData, size: 13, color: isSelectedSub ? brandPrimary : textSecondary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sub.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                          Text("${sub.docCount} docs", style: TextStyle(fontSize: 10, color: textSecondary.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelectedSub ? brandPrimary : Colors.transparent,
                        border: Border.all(color: isSelectedSub ? brandPrimary : borderMedium),
                      ),
                      child: isSelectedSub ? const Center(child: Icon(Icons.check, size: 10, color: Colors.white)) : null,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _showAddSubCategoryDialog(parent),
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: brandPrimary),
                  const SizedBox(width: 8),
                  Text("Add new sub-category", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: brandPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(bool isDark) {
    final bgPage = isDark ? const Color(0xFF0A0A0A) : AppTokens.lightBgPage;
    final bgSurface = isDark ? const Color(0xFF1C1C1C) : AppTokens.lightBgSurface;
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
    final textPrimary = isDark ? Colors.white : AppTokens.lightTextPrimary;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary = textSecondary.withValues(alpha: 0.6);
    final brandPrimary = isDark ? Colors.white : const Color(0xFF141414);

    final category = _selectedCategory;
    final inputFilled = _isYearMode 
        ? _yearController.text.trim().length == 4 
        : _nameController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(category.iconData, size: 16, color: brandPrimary),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedSubId != null)
                            Text(
                              _categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => category).name,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
                            ),
                          Text(
                            _selectedSubId != null ? category.name : category.name,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentStep = 0),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      foregroundColor: brandPrimary,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    child: const Text("Change"),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text(
            "IDENTIFICATION METHOD",
            style: AppTextStyles.bodyMd.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
            ),
            child: Row(
              children: [
                Expanded(child: _buildToggleOption("By Year", Icons.calendar_today_outlined, _isYearMode, () => setState(() => _isYearMode = true), isDark)),
                Expanded(child: _buildToggleOption("By File Name", Icons.title_outlined, !_isYearMode, () => setState(() => _isYearMode = false), isDark)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isYearMode ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("DOCUMENT YEAR", style: AppTextStyles.bodyMd.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: "e.g. 2006",
                    hintStyle: TextStyle(color: textTertiary),
                    prefixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: textTertiary),
                    counterText: "",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderLight, width: isDark ? 0.5 : 1.0)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderLight, width: isDark ? 0.5 : 1.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: brandPrimary)),
                    filled: true, fillColor: bgSurface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 6),
                Text("Enter the year this document was created (4 digits)", style: TextStyle(fontSize: 11, color: textTertiary)),
              ],
            ),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("DOCUMENT NAME", style: AppTextStyles.bodyMd.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: "e.g. BOA Minutes January 2006",
                    hintStyle: TextStyle(color: textTertiary),
                    prefixIcon: Icon(Icons.title_outlined, size: 18, color: textTertiary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderLight, width: isDark ? 0.5 : 1.0)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderLight, width: isDark ? 0.5 : 1.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: brandPrimary)),
                    filled: true, fillColor: bgSurface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 6),
                Text("Enter a descriptive name for this document", style: TextStyle(fontSize: 11, color: textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textSecondary,
                    side: BorderSide(color: borderLight, width: isDark ? 0.5 : 1.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 48),
                    textStyle: AppTextStyles.bodyMd.copyWith(fontSize: 14),
                  ),
                  child: const Text("Back"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: inputFilled ? () => setState(() => _currentStep = 2) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inputFilled ? brandPrimary : borderLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 48),
                    textStyle: AppTextStyles.bodyMd.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  child: const Text("Continue"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, IconData icon, bool isActive, VoidCallback onTap, bool isDark) {
    final brandPrimary = isDark ? Colors.white : const Color(0xFF141414);
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary = textSecondary.withValues(alpha: 0.6);

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isActive ? brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.white : textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3(bool isDark) {
    final bgSurface = isDark ? const Color(0xFF1C1C1C) : AppTokens.lightBgSurface;
    final bgPage = isDark ? const Color(0xFF0A0A0A) : AppTokens.lightBgPage;
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
    final textPrimary = isDark ? Colors.white : AppTokens.lightTextPrimary;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary = textSecondary.withValues(alpha: 0.6);
    final brandPrimary = isDark ? Colors.white : const Color(0xFF141414);

    final category = _selectedCategory;
    final mainCategoryName = _selectedSubId != null
        ? _categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => category!).name
        : category?.name ?? 'Unknown';

    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Confirm & Save", style: AppTextStyles.bodyMd.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 4),
          Text("Review document details before saving to vault", style: TextStyle(fontSize: 13, color: textSecondary)),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                _buildReviewRow(Icons.folder_outlined, "CATEGORY", mainCategoryName, bgPage, borderLight, textPrimary, textTertiary),
                Divider(height: 1, color: borderLight),
                _buildReviewRow(Icons.subdirectory_arrow_right, "SUB-CATEGORY", _selectedSubId != null ? category!.name : "None", bgPage, borderLight, textPrimary, textTertiary),
                Divider(height: 1, color: borderLight),
                if (_isYearMode)
                  _buildReviewRow(Icons.calendar_today_outlined, "YEAR", _yearController.text.trim(), bgPage, borderLight, textPrimary, textTertiary)
                else
                  _buildReviewRow(Icons.title_outlined, "FILE NAME", _finalDocumentName, bgPage, borderLight, textPrimary, textTertiary),
                Divider(height: 1, color: borderLight),
                _buildReviewRow(Icons.description_outlined, "FILE", widget.fileName, bgPage, borderLight, textPrimary, textTertiary),
                Divider(height: 1, color: borderLight),
                _buildReviewRow(Icons.menu_book_outlined, "PAGES", "${widget.pageCount} pages", bgPage, borderLight, textPrimary, textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _isUploading ? null : () => setState(() => _currentStep = 1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textSecondary,
                    side: BorderSide(color: borderLight, width: isDark ? 0.5 : 1.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 48),
                    textStyle: AppTextStyles.bodyMd.copyWith(fontSize: 14),
                  ),
                  child: const Text("Back"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadDocument,
                  icon: _isUploading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload_outlined, size: 16, color: Colors.white),
                  label: Text(
                    _isUploading ? "Saving..." : "Save Document",
                    style: AppTextStyles.bodyMd.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ),
          if (_isUploading) ...[
             const SizedBox(height: 20),
             Text(_uploadStatus, style: TextStyle(fontSize: 12, color: textSecondary)),
             const SizedBox(height: 8),
             LinearProgressIndicator(value: _rawUploadFraction ?? _uploadProgress, backgroundColor: borderLight, color: brandPrimary),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewRow(IconData icon, String label, String value, Color bgPage, Color borderLight, Color textPrimary, Color textTertiary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: bgPage, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0)),
            child: Center(child: Icon(icon, size: 15, color: textTertiary)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: textTertiary)),
              const SizedBox(height: 2),
              SizedBox(
                width: 200,
                child: Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuccessBottomSheet extends StatelessWidget {
  final String categoryName;
  final Color categoryColor;
  final String finalYearLabel;
  final int pageCount;
  final VoidCallback onView;
  final VoidCallback onHome;

  const _SuccessBottomSheet({
    required this.categoryName,
    required this.categoryColor,
    required this.finalYearLabel,
    required this.pageCount,
    required this.onView,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSurface = isDark ? const Color(0xFF1C1C1C) : AppTokens.lightBgSurface;
    final textPrimary = isDark ? Colors.white : AppTokens.lightTextPrimary;
    final textSecondary = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final brandPrimary = isDark ? Colors.white : const Color(0xFF141414);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: brandPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: brandPrimary.withValues(alpha: 0.2), width: 2),
            ),
            child: Center(
              child: Icon(Icons.check_circle_rounded, size: 40, color: brandPrimary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Document Saved!',
            style: AppTextStyles.bodyMd.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Successfully added to $categoryName',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: categoryColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('$finalYearLabel · $pageCount pages', style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: textPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: onView,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('View Document', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onHome,
            child: Text(
              'Back to Home',
              style: AppTextStyles.bodyMd.copyWith(fontSize: 13, color: brandPrimary),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
