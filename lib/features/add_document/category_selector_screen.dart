// lib/features/add_document/category_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/data/mock_data.dart';
import 'package:gda_vault_ai/models/category_model.dart';

/// A 3-step flow for categorizing, dating, and uploading a document.
class CategorySelectorScreen extends StatefulWidget {
  final String source;
  final int pageCount;
  final String fileName;
  final int? fileSize;

  const CategorySelectorScreen({
    super.key,
    required this.source,
    required this.pageCount,
    required this.fileName,
    this.fileSize,
  });

  @override
  State<CategorySelectorScreen> createState() => _CategorySelectorScreenState();
}

class _CategorySelectorScreenState extends State<CategorySelectorScreen> {
  int _currentStep = 0;
  String? _selectedCategoryId;
  String? _selectedSubId;
  String _yearInputType = 'single';
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _fromYearController = TextEditingController();
  final TextEditingController _toYearController = TextEditingController();

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  CategoryModel? get _selectedCategory =>
      _selectedCategoryId != null ? MockData.categories.firstWhere((c) => c.id == _selectedCategoryId) : null;

  String get _finalYearLabel {
    if (_yearInputType == 'single') return _yearController.text;
    if (_yearInputType == 'range') return "${_fromYearController.text}–${_toYearController.text}";
    return "${_fromYearController.text}–Ongoing";
  }

  void _uploadDocument() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final phases = [
      "Optimizing scanned pages...",
      "Generating searchable PDF...",
      "Applying GDA watermark...",
      "Encrypting for secure archive...",
      "Uploading to Vault..."
    ];

    for (int i = 0; i < phases.length; i++) {
      if (!mounted) return;
      setState(() {
        _uploadStatus = phases[i];
      });
      
      // Progress within each phase
      double start = i / phases.length;
      double end = (i + 1) / phases.length;
      
      for (double p = start; p <= end; p += 0.02) {
        await Future.delayed(const Duration(milliseconds: 40));
        if (!mounted) return;
        setState(() => _uploadProgress = p);
      }
    }

    if (mounted) {
      setState(() => _isUploading = false);
      _showSuccessSheet();
    }
  }

  String _uploadStatus = "Preparing...";

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SuccessBottomSheet(
        categoryName: _selectedCategory?.name ?? "",
        categoryColor: _selectedCategory?.color ?? AppColors.gold,
        finalYearLabel: _finalYearLabel,
        pageCount: widget.pageCount,
        onView: () {
          Navigator.pop(ctx);
          context.go('/dashboard'); // Mock navigation to home or doc view
        },
        onHome: () {
          Navigator.pop(ctx);
          context.go('/dashboard');
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
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Column(
          children: [
            Text(
              "Save Document",
              style: AppTextStyles.playfairDisplay.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              "Step ${_currentStep + 1} of 3",
              style: AppTextStyles.dmSans.copyWith(fontSize: 9, color: Colors.white.withOpacity(0.5)),
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
              duration: const Duration(milliseconds: 400),
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
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppColors.gdaGreen : (isActive ? AppColors.gold : Colors.white.withOpacity(0.15)),
                    border: isActive ? Border.all(color: AppColors.gold.withOpacity(0.4), width: 2) : null,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : Text("${index + 1}",
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive ? AppColors.navyDark : Colors.white.withOpacity(0.5),
                            )),
                  ),
                ),
                AppSpacing.horizontal(6),
                Text(
                  ['Category', 'Year', 'Upload'][index],
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? AppColors.gold : (isDone ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.3)),
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 1.5,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: isDone ? AppColors.gdaGreen.withOpacity(0.5) : Colors.white.withOpacity(0.15),
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
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Choose Category", style: AppTextStyles.playfairDisplay.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.charcoal)),
          AppSpacing.vertical(4),
          Text("Where should this document be filed?", style: AppTextStyles.dmSans.copyWith(fontSize: 13, color: AppColors.charcoal.withOpacity(0.5))),
          AppSpacing.vertical(20),
          _buildSourceFileInfo(isDark),
          AppSpacing.vertical(20),
          Text("Main Categories", style: AppTextStyles.dmSans.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.charcoal.withOpacity(0.45), letterSpacing: 0.8)),
          AppSpacing.vertical(10),
          ...MockData.categories.map((cat) => _buildCategoryTile(cat, isDark)),
          AppSpacing.vertical(24),
          _buildPrimaryButton(
            "Continue",
            enabled: _selectedCategoryId != null && (_selectedCategory?.hasSubCategories == false || _selectedSubId != null),
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
          Text("Document Year", style: AppTextStyles.playfairDisplay.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.charcoal)),
          AppSpacing.vertical(4),
          Text("When was this document created?", style: AppTextStyles.dmSans.copyWith(fontSize: 13, color: AppColors.charcoal.withOpacity(0.5))),
          AppSpacing.vertical(20),
          _buildSelectedCategorySummary(isDark),
          AppSpacing.vertical(24),
          Text("Enter Year or Range", style: AppTextStyles.dmSans.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.charcoal.withOpacity(0.45), letterSpacing: 0.8)),
          AppSpacing.vertical(12),
          _buildYearOption(
            type: 'single',
            title: "Single Year",
            subtitle: "e.g. 1996, 2024",
            isDark: isDark,
          ),
          AppSpacing.vertical(10),
          _buildYearOption(
            type: 'range',
            title: "Year Range",
            subtitle: "e.g. 1961–1996",
            isDark: isDark,
          ),
          AppSpacing.vertical(10),
          _buildYearOption(
            type: 'ongoing',
            title: "Ongoing",
            subtitle: "e.g. 2025–onwards (active)",
            isDark: isDark,
          ),
          AppSpacing.vertical(20),
          _buildYearInputFields(isDark),
          AppSpacing.vertical(24),
          Row(
            children: [
              Expanded(child: _buildSecondaryButton("Back", onTap: () => setState(() => _currentStep = 0), isDark: isDark)),
              AppSpacing.horizontal(12),
              Expanded(
                child: _buildPrimaryButton(
                  "Continue",
                  enabled: (_yearInputType == 'single' && _yearController.text.length == 4) ||
                      (_yearInputType == 'range' && _fromYearController.text.length == 4 && _toYearController.text.length == 4) ||
                      (_yearInputType == 'ongoing' && _fromYearController.text.length == 4),
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
          Text("Confirm & Save", style: AppTextStyles.playfairDisplay.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.charcoal)),
          AppSpacing.vertical(4),
          Text("Review details before saving", style: AppTextStyles.dmSans.copyWith(fontSize: 13, color: AppColors.charcoal.withOpacity(0.5))),
          AppSpacing.vertical(20),
          _buildConfirmationSummary(isDark),
          AppSpacing.vertical(20),
          if (_isUploading) _buildUploadProgress(isDark),
          AppSpacing.vertical(20),
          Row(
            children: [
              Expanded(child: _buildSecondaryButton("Back", enabled: !_isUploading, onTap: () => setState(() => _currentStep = 1), isDark: isDark)),
              AppSpacing.horizontal(12),
              Expanded(
                child: _buildPrimaryButton(
                  _isUploading ? "Saving..." : "Save Document",
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

  Widget _buildSourceFileInfo(bool isDark) {
    final sizeStr = widget.fileSize != null ? "${(widget.fileSize! / 1048576).toStringAsFixed(1)} MB" : "${widget.pageCount} pages scanned";
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navyDark.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.catBoard.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.picture_as_pdf, size: 18, color: AppColors.catBoard),
          ),
          AppSpacing.horizontal(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.fileName, style: AppTextStyles.dmSans.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.charcoal), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(sizeStr, style: AppTextStyles.dmSans.copyWith(fontSize: 11, color: AppColors.charcoal.withOpacity(0.45))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.source == 'scanner' ? AppColors.catBoard.withOpacity(0.1) : AppColors.gdaGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.source == 'scanner' ? "SCANNED" : "IMPORTED",
              style: AppTextStyles.dmSans.copyWith(fontSize: 8, fontWeight: FontWeight.bold, color: widget.source == 'scanner' ? AppColors.catBoard : AppColors.gdaGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(CategoryModel category, bool isDark) {
    final isSelected = _selectedCategoryId == category.id;
    return Column(
      children: [
        AnimatedContainer(
          margin: const EdgeInsets.only(bottom: 10),
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? category.color.withOpacity(0.08) : (isDark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? category.color : AppColors.divider, width: isSelected ? 1.5 : 0.8),
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
                        color: category.color.withOpacity(isSelected ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(category.iconData, size: 20, color: category.color),
                    ),
                    AppSpacing.horizontal(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(category.name, style: AppTextStyles.dmSans.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.charcoal)),
                              if (category.hasSubCategories) ...[
                                AppSpacing.horizontal(6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Text("has sub-types", style: AppTextStyles.dmSans.copyWith(fontSize: 8, color: AppColors.gold)),
                                ),
                              ],
                            ],
                          ),
                          AppSpacing.vertical(2),
                          Text("${category.docCount} docs · ${category.yearRange}", style: AppTextStyles.dmSans.copyWith(fontSize: 11, color: AppColors.charcoal.withOpacity(0.4))),
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
                        border: Border.all(color: isSelected ? category.color : AppColors.divider.withOpacity(0.8), width: 2),
                      ),
                      child: isSelected ? const Center(child: Icon(Icons.check_rounded, size: 12, color: Colors.white)) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isSelected && category.hasSubCategories)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(top: 4, left: 16),
            padding: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: category.color.withOpacity(0.3), width: 2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Select sub-type:", style: AppTextStyles.dmSans.copyWith(fontSize: 11, color: AppColors.charcoal.withOpacity(0.5))),
                AppSpacing.vertical(8),
                ...category.subCategories!.map((sub) {
                  final subSelected = _selectedSubId == sub;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSubId = sub),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: subSelected ? category.color.withOpacity(0.08) : (isDark ? AppColors.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: subSelected ? category.color : AppColors.divider, width: subSelected ? 1.2 : 0.8),
                      ),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: subSelected ? category.color : AppColors.divider)),
                          AppSpacing.horizontal(10),
                          Expanded(child: Text(sub, style: AppTextStyles.dmSans.copyWith(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.charcoal))),
                          if (subSelected) Icon(Icons.check_circle, size: 16, color: category.color),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _selectedCategory!.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _selectedCategory!.color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(_selectedCategory!.iconData, size: 16, color: _selectedCategory!.color),
          AppSpacing.horizontal(8),
          Expanded(
            child: Text(
              _selectedSubId ?? _selectedCategory!.name,
              style: AppTextStyles.dmSans.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.charcoal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _currentStep = 0),
            child: Text("Change", style: AppTextStyles.dmSans.copyWith(fontSize: 11, color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  Widget _buildYearOption({required String type, required String title, required String subtitle, required bool isDark}) {
    final isSelected = _yearInputType == type;
    return GestureDetector(
      onTap: () => setState(() => _yearInputType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.catBoard.withOpacity(0.06) : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.catBoard : AppColors.divider, width: isSelected ? 1.5 : 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppColors.catBoard : AppColors.divider, width: isSelected ? 5 : 1.5),
                color: Colors.transparent,
              ),
            ),
            AppSpacing.horizontal(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.charcoal)),
                Text(subtitle, style: AppTextStyles.dmSans.copyWith(fontSize: 11, color: AppColors.charcoal.withOpacity(0.4))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearInputFields(bool isDark) {
    if (_yearInputType == 'single') {
      return _buildYearTextField(controller: _yearController, label: "Year", hint: "e.g. 1996");
    }
    if (_yearInputType == 'range') {
      return Row(
        children: [
          Expanded(child: _buildYearTextField(controller: _fromYearController, label: "From Year", hint: "1961")),
          AppSpacing.horizontal(12),
          Container(width: 10, height: 1.5, color: AppColors.divider),
          AppSpacing.horizontal(12),
          Expanded(child: _buildYearTextField(controller: _toYearController, label: "To Year", hint: "1996")),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: _buildYearTextField(controller: _fromYearController, label: "From Year", hint: "2025")),
        AppSpacing.horizontal(12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.gdaGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gdaGreen.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ongoing", style: AppTextStyles.dmSans.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gdaGreen)),
                Text("No end year", style: AppTextStyles.dmSans.copyWith(fontSize: 9, color: AppColors.charcoal.withOpacity(0.4))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearTextField({required TextEditingController controller, required String label, required String hint}) {
    return TextFormField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      keyboardType: TextInputType.number,
      maxLength: 4,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.dmSans.copyWith(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: "",
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
        prefixIcon: const Icon(Icons.calendar_today, size: 18, color: AppColors.gold),
        suffixIcon: controller.text.length == 4 ? const Icon(Icons.check_circle, size: 18, color: AppColors.gdaGreen) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
      ),
    );
  }

  Widget _buildConfirmationSummary(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(color: _selectedCategory?.color, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _buildDetailRow(icon: Icons.folder_rounded, label: "Category", value: _selectedCategory?.name ?? "", valueColor: _selectedCategory?.color, isDark: isDark),
                const Divider(height: 1),
                _buildDetailRow(icon: Icons.subdirectory_arrow_right, label: "Sub-category", value: _selectedSubId ?? "—", isDark: isDark),
                const Divider(height: 1),
                _buildDetailRow(icon: Icons.calendar_today_rounded, label: "Year", value: _finalYearLabel, isDark: isDark),
                const Divider(height: 1),
                _buildDetailRow(icon: Icons.description_rounded, label: "File", value: widget.fileName, maxLines: 2, isDark: isDark),
                const Divider(height: 1),
                _buildDetailRow(icon: Icons.menu_book_rounded, label: "Pages", value: "${widget.pageCount} pages", isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value, Color? valueColor, int maxLines = 1, required bool isDark}) {
    final themeColor = valueColor ?? (isDark ? AppColors.darkText : AppColors.charcoal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: themeColor),
          ),
          AppSpacing.horizontal(12),
          SizedBox(
            width: 80,
            child: Text(label, style: AppTextStyles.dmSans.copyWith(fontSize: 12, color: AppColors.charcoal.withOpacity(0.5))),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.dmSans.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: themeColor),
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
        color: AppColors.navyDark.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(value: _uploadProgress, color: AppColors.gold, backgroundColor: AppColors.divider, strokeWidth: 2.5),
          ),
          AppSpacing.horizontal(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_uploadStatus, style: AppTextStyles.dmSans.copyWith(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.charcoal)),
                AppSpacing.vertical(4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: _uploadProgress, backgroundColor: AppColors.divider, valueColor: const AlwaysStoppedAnimation(AppColors.gold), minHeight: 4),
                ),
              ],
            ),
          ),
          AppSpacing.horizontal(12),
          Text("${(_uploadProgress * 100).toInt()}%", style: AppTextStyles.dmSans.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.gold)),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String label, {required bool enabled, required VoidCallback onTap}) {
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
              colors: enabled ? [AppColors.navyDark, const Color(0xFF1A3A6B)] : [AppColors.charcoal.withOpacity(0.3), AppColors.charcoal.withOpacity(0.2)],
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: enabled ? [BoxShadow(color: AppColors.navyDark.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Center(child: Text(label, style: AppTextStyles.dmSans.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, {bool enabled = true, required VoidCallback onTap, required bool isDark}) {
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
          child: Text(label, style: AppTextStyles.dmSans.copyWith(fontSize: 14, color: (isDark ? AppColors.darkText : AppColors.charcoal).withOpacity(0.6))),
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
              color: AppColors.gdaGreen.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gdaGreen.withOpacity(0.2), width: 2),
            ),
            child: const Center(child: Icon(Icons.check_circle_rounded, size: 40, color: AppColors.gdaGreen)),
          ),
          AppSpacing.vertical(16),
          Text("Document Saved!", style: AppTextStyles.playfairDisplay.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
          AppSpacing.vertical(8),
          Text("Successfully added to $categoryName", textAlign: TextAlign.center, style: AppTextStyles.dmSans.copyWith(fontSize: 13, color: AppColors.charcoal.withOpacity(0.5))),
          AppSpacing.vertical(12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: categoryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: categoryColor, shape: BoxShape.circle)),
                AppSpacing.horizontal(8),
                Text("$finalYearLabel · $pageCount pages", style: AppTextStyles.dmSans.copyWith(fontSize: 12)),
              ],
            ),
          ),
          AppSpacing.vertical(28),
          _buildPrimaryButton("View Document", onTap: onView),
          AppSpacing.vertical(10),
          TextButton(
            onPressed: onHome,
            child: Text("Back to Home", style: AppTextStyles.dmSans.copyWith(fontSize: 13, color: AppColors.gold)),
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
          gradient: const LinearGradient(colors: [AppColors.navyDark, Color(0xFF1A3A6B)]),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [BoxShadow(color: AppColors.navyDark.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Center(child: Text(label, style: AppTextStyles.dmSans.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))),
      ),
    );
  }
}
