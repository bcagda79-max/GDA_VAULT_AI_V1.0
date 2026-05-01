import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/services/document_upload_service.dart';
import 'package:gda_vault_ai/core/services/supabase_service.dart';
import 'package:gda_vault_ai/models/category_model.dart';

/// A 3-step flow for categorizing, dating, and uploading a document.
class CategorySelectorScreen extends StatefulWidget {
  final String source;
  final int pageCount;
  final String fileName;
  final int? fileSize;
  final List<String> imagePaths;
  final String? filePath;

  const CategorySelectorScreen({
    super.key,
    required this.source,
    required this.pageCount,
    required this.fileName,
    this.fileSize,
    this.imagePaths = const [],
    this.filePath,
  });

  @override
  State<CategorySelectorScreen> createState() => _CategorySelectorScreenState();
}

class _CategorySelectorScreenState extends State<CategorySelectorScreen> {
  final _supa = SupabaseService.instance;
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _fromYearController = TextEditingController();
  final TextEditingController _toYearController = TextEditingController();

  int _currentStep = 0;
  String? _selectedCategoryId;
  String? _selectedSubId;
  String _yearInputType = 'single';
  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = 'Preparing...';
  String? _error;
  List<CategoryModel> _categories = const [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _yearController.dispose();
    _fromYearController.dispose();
    _toYearController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rows = await _supa.getAllCategories();
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
    if (_yearInputType == 'single') return _yearController.text.trim();
    if (_yearInputType == 'range') {
      return '${_fromYearController.text.trim()}–${_toYearController.text.trim()}';
    }
    return '${_fromYearController.text.trim()}–Ongoing';
  }

  Future<void> _uploadDocument() async {
    final category = _selectedCategory;
    if (category == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing...';
    });

    try {
      final yearStart =
          int.tryParse(_fromYearController.text.trim()) ??
          int.tryParse(_yearController.text.trim()) ??
          DateTime.now().year;
      final mainCategoryId = category.parentId ?? category.id;
      final subCategoryId = category.parentId != null ? category.id : null;

      UploadResult result;
      if (widget.source == 'scanner') {
        result = await DocumentUploadService.instance.uploadScannedImages(
          imagePaths: widget.imagePaths,
          category: mainCategoryId,
          subCategory: subCategoryId,
          categoryStoragePath: category.storagePath,
          year: yearStart,
          fileName: widget.fileName,
          onProgress: (phase, progress) {
            if (!mounted) return;
            setState(() {
              _uploadStatus = phase;
              _uploadProgress = progress;
            });
          },
        );
      } else {
        final filePath = widget.filePath;
        if (filePath == null || filePath.isEmpty) {
          throw StateError('Missing file path for imported PDF');
        }
        final pdfFile = File(filePath);
        result = await DocumentUploadService.instance.uploadPdfFile(
          pdfFile: pdfFile,
          category: mainCategoryId,
          subCategory: subCategoryId,
          categoryStoragePath: category.storagePath,
          year: yearStart,
          fileName: widget.fileName,
          pageCount: widget.pageCount,
          onProgress: (phase, progress) {
            if (!mounted) return;
            setState(() {
              _uploadStatus = phase;
              _uploadProgress = progress;
            });
          },
        );
      }

      if (!mounted) return;
      setState(() => _isUploading = false);
      if (result.success) {
        _showSuccessSheet(result);
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

  void _showSuccessSheet(UploadResult result) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SuccessBottomSheet(
        categoryName: _selectedCategory?.name ?? '',
        categoryColor: _selectedCategory?.color ?? AppColors.gold,
        finalYearLabel: _finalYearLabel,
        pageCount: widget.pageCount,
        onView: () async {
          Navigator.pop(ctx); // Close success sheet
          
          // Slight delay to allow the sheet to dismiss fully before navigation
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;

          // Find the main category for the route path
          final mainCategory = _selectedCategory?.parentId != null
              ? _categories.firstWhere((c) => c.id == _selectedCategory!.parentId, orElse: () => _selectedCategory!)
              : _selectedCategory!;

          // Use context.go to navigate directly and reset the upload stack
          context.go(
            '/categories/sub/${mainCategory.id}/years',
            extra: {
              'categoryName': mainCategory.name,
              'subCategoryName': _selectedCategory?.parentId != null ? _selectedCategory?.name : null,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppColors.navyDark, AppColors.navyDark.withValues(alpha: 0.8)]
                  : [AppColors.navyDark, AppColors.navyLight],
            ),
          ),
        ),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Column(
          children: [
            Text(
              'Save Document',
              style: AppTextStyles.playfairDisplay.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Step ${_currentStep + 1} of 3',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepperIndicator(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentStep(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperIndicator() {
    return Container(
      color: AppColors.navyDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index == _currentStep;
          final isDone = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.gdaGreen
                        : (isActive
                              ? AppColors.gold
                              : Colors.white.withValues(alpha: 0.15)),
                    border: isActive
                        ? Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4),
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : Text(
                            '${index + 1}',
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? AppColors.navyDark
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                ),
                AppSpacing.horizontal(6),
                Text(
                  ['Category', 'Year', 'Upload'][index],
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? AppColors.gold
                        : (isDone
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.3)),
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 1.5,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: isDone
                          ? AppColors.gdaGreen.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(isDark);
      case 1:
        return _buildStep2(isDark);
      case 2:
        return _buildStep3(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_error != null && _categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.gold,
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load categories',
                style: AppTextStyles.playfairDisplay.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadCategories,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Category',
            style: AppTextStyles.playfairDisplay.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.charcoal,
            ),
          ),
          AppSpacing.vertical(4),
          Text(
            'Where should this document be filed?',
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 13,
              color: isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.charcoal.withValues(alpha: 0.5),
            ),
          ),
          AppSpacing.vertical(20),
          _buildSourceFileInfo(isDark),
          AppSpacing.vertical(20),
          Text(
            'Main Categories',
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.charcoal.withValues(alpha: 0.45),
              letterSpacing: 0.8,
            ),
          ),
          AppSpacing.vertical(10),
          ..._topCategories.map((cat) => _buildCategoryTile(cat, isDark)),
          AppSpacing.vertical(24),
          _buildPrimaryButton(
            'Continue',
            enabled:
                _selectedCategory != null &&
                (!_selectedCategoryHasChildren || _selectedSubId != null),
            onTap: () => setState(() => _currentStep = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Document Year',
            style: AppTextStyles.playfairDisplay.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.charcoal,
            ),
          ),
          AppSpacing.vertical(4),
          Text(
            'When was this document created?',
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 13,
              color: isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.charcoal.withValues(alpha: 0.5),
            ),
          ),
          AppSpacing.vertical(20),
          _buildSelectedCategorySummary(isDark),
          AppSpacing.vertical(24),
          _buildYearInputFields(),
          AppSpacing.vertical(24),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  'Back',
                  onTap: () => setState(() => _currentStep = 0),
                  isDark: isDark,
                ),
              ),
              AppSpacing.horizontal(12),
              Expanded(
                child: _buildPrimaryButton(
                  'Continue',
                  enabled: _isYearInputValid,
                  onTap: () => setState(() => _currentStep = 2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm & Save',
            style: AppTextStyles.playfairDisplay.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.charcoal,
            ),
          ),
          AppSpacing.vertical(4),
          Text(
            'Review details before saving',
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 13,
              color: isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.charcoal.withValues(alpha: 0.5),
            ),
          ),
          AppSpacing.vertical(20),
          _buildConfirmationSummary(isDark),
          AppSpacing.vertical(20),
          if (_isUploading) _buildUploadProgress(isDark),
          AppSpacing.vertical(20),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  'Back',
                  enabled: !_isUploading,
                  onTap: () => setState(() => _currentStep = 1),
                  isDark: isDark,
                ),
              ),
              AppSpacing.horizontal(12),
              Expanded(
                child: _buildPrimaryButton(
                  _isUploading ? 'Saving...' : 'Save Document',
                  enabled: !_isUploading,
                  onTap: _uploadDocument,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _isYearInputValid {
    if (_yearInputType == 'single') {
      return _yearController.text.trim().length == 4;
    }
    if (_yearInputType == 'range') {
      return _fromYearController.text.trim().length == 4 &&
          _toYearController.text.trim().length == 4;
    }
    return _fromYearController.text.trim().length == 4;
  }

  Widget _buildSourceFileInfo(bool isDark) {
    final sizeStr = widget.fileSize != null
        ? '${(widget.fileSize! / 1048576).toStringAsFixed(1)} MB'
        : '${widget.pageCount} pages scanned';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.navyDark.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.catBoard.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              size: 18,
              color: AppColors.catBoard,
            ),
          ),
          AppSpacing.horizontal(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fileName,
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.charcoal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sizeStr,
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 11,
                    color: (isDark ? AppColors.darkText : AppColors.charcoal).withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.source == 'scanner'
                  ? AppColors.catBoard.withValues(alpha: 0.1)
                  : AppColors.gdaGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.source == 'scanner' ? 'SCANNED' : 'IMPORTED',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: widget.source == 'scanner'
                    ? AppColors.catBoard
                    : AppColors.gdaGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(CategoryModel category, bool isDark) {
    final isSelected = _selectedCategoryId == category.id;
    final children = _childrenOf(category.id);
    return Column(
      children: [
        AnimatedContainer(
          margin: const EdgeInsets.only(bottom: 10),
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? category.color.withValues(alpha: 0.08)
                : (isDark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? category.color : AppColors.divider,
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() {
                _selectedCategoryId = category.id;
                _selectedSubId = null;
              }),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: category.color.withValues(
                          alpha: isSelected ? 0.15 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        category.iconData,
                        size: 20,
                        color: category.color,
                      ),
                    ),
                    AppSpacing.horizontal(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  category.name,
                                  style: AppTextStyles.dmSans.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.darkText
                                        : AppColors.charcoal,
                                  ),
                                ),
                              ),
                              if (children.isNotEmpty) ...[
                                AppSpacing.horizontal(6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${children.length} sub',
                                    style: AppTextStyles.dmSans.copyWith(
                                      fontSize: 8,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          AppSpacing.vertical(2),
                          Text(
                            '${category.docCount} docs · ${category.yearRange}',
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 11,
                              color: (isDark ? AppColors.darkText : AppColors.charcoal).withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? category.color : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? category.color
                              : AppColors.divider.withValues(alpha: 0.8),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isSelected && children.isNotEmpty)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(top: 4, left: 16),
            padding: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: category.color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select sub-type:',
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 11,
                    color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.charcoal.withValues(alpha: 0.5),
                  ),
                ),
                AppSpacing.vertical(8),
                ...children.map((sub) {
                  final subSelected = _selectedSubId == sub.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSubId = sub.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: subSelected
                            ? category.color.withValues(alpha: 0.08)
                            : (isDark ? AppColors.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: subSelected
                              ? category.color
                              : AppColors.divider,
                          width: subSelected ? 1.2 : 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: subSelected
                                  ? category.color
                                  : AppColors.divider,
                            ),
                          ),
                          AppSpacing.horizontal(10),
                          Expanded(
                            child: Text(
                              sub.name,
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkText
                                    : AppColors.charcoal,
                              ),
                            ),
                          ),
                          if (subSelected)
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: category.color,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedCategorySummary(bool isDark) {
    final category = _selectedCategory;
    if (category == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: category.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(category.iconData, size: 16, color: category.color),
          AppSpacing.horizontal(8),
          Expanded(
            child: Text(
              _selectedSubId != null
                  ? _categories.firstWhere((c) => c.id == _selectedSubId).name
                  : category.name,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.charcoal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _currentStep = 0),
            child: Text(
              'Change',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 11,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearInputFields() {
    return _buildYearTextField(
      controller: _yearController,
      label: 'Year',
      hint: 'e.g. 1996',
    );
  }

  Widget _buildYearTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      keyboardType: TextInputType.number,
      maxLength: 4,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.dmSans.copyWith(
        fontSize: 14,
        color: isDark ? AppColors.darkText : AppColors.charcoal,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? AppColors.darkText.withValues(alpha: 0.7) : AppColors.charcoal.withValues(alpha: 0.7),
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkText.withValues(alpha: 0.3) : AppColors.charcoal.withValues(alpha: 0.3),
        ),
        counterText: '',
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
        prefixIcon: const Icon(
          Icons.calendar_today,
          size: 18,
          color: AppColors.gold,
        ),
        suffixIcon: controller.text.length == 4
            ? const Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.gdaGreen,
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.divider,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildConfirmationSummary(bool isDark) {
    final category = _selectedCategory;
    if (category == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.folder_rounded,
                  label: 'Category',
                  value: _selectedCategoryId != null 
                      ? _categories.firstWhere((c) => c.id == _selectedCategoryId).name
                      : category.name,
                  valueColor: isDark ? Colors.white : category.color,
                  isDark: isDark,
                ),
                const Divider(height: 1),
                _buildDetailRow(
                  icon: Icons.subdirectory_arrow_right,
                  label: 'Sub-category',
                  value: _selectedSubId != null
                      ? _categories
                            .firstWhere((c) => c.id == _selectedSubId)
                            .name
                      : '—',
                  isDark: isDark,
                ),
                const Divider(height: 1),
                _buildDetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Year',
                  value: _finalYearLabel,
                  isDark: isDark,
                ),
                const Divider(height: 1),
                _buildDetailRow(
                  icon: Icons.description_rounded,
                  label: 'File',
                  value: widget.fileName,
                  maxLines: 2,
                  isDark: isDark,
                ),
                const Divider(height: 1),
                _buildDetailRow(
                  icon: Icons.menu_book_rounded,
                  label: 'Pages',
                  value: '${widget.pageCount} pages',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    int maxLines = 1,
    required bool isDark,
  }) {
    final themeColor =
        valueColor ?? (isDark ? AppColors.darkText : AppColors.charcoal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: themeColor),
          ),
          AppSpacing.horizontal(12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 12,
                color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.charcoal.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyDark.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: _uploadProgress,
              color: AppColors.gold,
              backgroundColor: AppColors.divider,
              strokeWidth: 2.5,
            ),
          ),
          AppSpacing.horizontal(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _uploadStatus,
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 13,
                    color: isDark ? AppColors.darkText : AppColors.charcoal,
                  ),
                ),
                AppSpacing.vertical(4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.horizontal(12),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(
    String label, {
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? [AppColors.navyDark, const Color(0xFF1A3A6B)]
                  : [
                      AppColors.charcoal.withValues(alpha: 0.3),
                      AppColors.charcoal.withValues(alpha: 0.2),
                    ],
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.navyDark.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    String label, {
    bool enabled = true,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.divider, width: 1.2),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 14,
              color: (isDark ? AppColors.darkText : AppColors.charcoal)
                  .withValues(alpha: 0.6),
            ),
          ),
        ),
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

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.gdaGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gdaGreen.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_rounded,
                size: 40,
                color: AppColors.gdaGreen,
              ),
            ),
          ),
          AppSpacing.vertical(16),
          Text(
            'Document Saved!',
            style: AppTextStyles.playfairDisplay.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.vertical(8),
          Text(
            'Successfully added to $categoryName',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 13,
              color: AppColors.charcoal.withValues(alpha: 0.5),
            ),
          ),
          AppSpacing.vertical(12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                AppSpacing.horizontal(8),
                Text(
                  '$finalYearLabel · $pageCount pages',
                  style: AppTextStyles.dmSans.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          AppSpacing.vertical(28),
          _buildPrimaryButton('View Document', onTap: onView),
          AppSpacing.vertical(10),
          TextButton(
            onPressed: onHome,
            child: Text(
              'Back to Home',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 13,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navyDark, Color(0xFF1A3A6B)],
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
