// lib/features/categories/subcategory_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/services/api_service.dart';
import 'package:gda_vault_ai/models/category_model.dart';

class SubcategoryScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final Color categoryColor;

  const SubcategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
  final _api = ApiService.instance;
  bool _isLoading = true;
  List<CategoryModel> _subCategories = const [];

  @override
  void initState() {
    super.initState();
    _loadSubCategories();
  }

  Future<void> _loadSubCategories() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getSubCategories(widget.categoryId);
      final rawSubCats = data.map(CategoryModel.fromMap).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final countsFutures = rawSubCats.map((cat) async {
        try {
          final docs = await _api.getDocumentsByCategory(cat.id);
          return cat.copyWith(docCount: docs.length);
        } catch (e) {
          return cat;
        }
      });

      final subCats = await Future.wait(countsFutures);

      if (!mounted) return;
      setState(() {
        _subCategories = subCats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading subcategories: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _calculateYearCount(CategoryModel sub) {
    if (sub.yearFrom == null) return "Unknown";
    final to = sub.yearTo ?? DateTime.now().year;
    final diff = to - sub.yearFrom! + 1;
    return "$diff years";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: isDark ? AppTokens.darkBgPage : AppTokens.lightBgPage,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 860;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                if (!isDesktop) _buildMobileHeader(context),
                if (isDesktop) _buildDesktopHeader(isDark),

                // SECTION LABEL
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      isDesktop ? 32 : 16, 16, 16, 8),
                  child: Text(
                    'SELECT SUB-CATEGORY',
                    style: AppTextStyles.labelSm.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTokens.darkTextSecondary
                          : AppTokens.lightTextSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),

                // LIST
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTokens.lightBrandPrimary,
                          ),
                        )
                      : _subCategories.isEmpty
                          ? _buildEmptyState(isDark)
                          : RefreshIndicator(
                              color: isDark
                                  ? AppTokens.darkBrandPrimary
                                  : AppTokens.lightBrandPrimary,
                              onRefresh: _loadSubCategories,
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 32 : 0,
                                  vertical: 4,
                                ),
                                itemCount: _subCategories.length,
                                itemBuilder: (context, index) {
                                  final sub = _subCategories[index];
                                  return _SubCategoryCard(
                                    subCategoryName: sub.name,
                                    description:
                                        "Official documents for ${sub.name}",
                                    docCount: sub.docCount,
                                    yearCount: _calculateYearCount(sub),
                                    firstYear:
                                        sub.yearFrom?.toString() ?? "N/A",
                                    lastYear:
                                        sub.yearTo?.toString() ?? "Now",
                                    onTap: () {
                                      context.push(
                                        '/categories/sub/${sub.id}/years',
                                        extra: {
                                          'categoryName':
                                              widget.categoryName,
                                          'subCategoryName': sub.name,
                                          'categoryColor': sub.color,
                                          'yearFrom': sub.yearFrom ?? 1961,
                                          'yearTo': sub.yearTo,
                                          'subCategoryId': sub.id,
                                        },
                                      );
                                    },
                                  )
                                      .animate(
                                          delay: (100 * index).ms)
                                      .fadeIn(duration: 250.ms)
                                      .slideY(
                                          begin: 0.04,
                                          end: 0,
                                          curve: Curves.easeOut);
                                },
                              ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── MOBILE HEADER ──────────────────────────────────────
  Widget _buildMobileHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56,
      color: isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(
              Icons.arrow_back,
              size: 20,
              color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.categoryName,
                style: AppTextStyles.headingSm.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  // ── DESKTOP HEADER ─────────────────────────────────────
  Widget _buildDesktopHeader(bool isDark) {
    final textTertiary =
        isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final textPrimary =
        isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  'Categories',
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 13,
                    color: textTertiary,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.chevron_right, size: 16, color: textTertiary),
              ),
              Text(
                widget.categoryName,
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 13,
                  color: isDark
                      ? AppTokens.darkTextPrimary
                      : AppTokens.lightTextPrimary,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.categoryName,
            style: AppTextStyles.headingLg.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final textSecondary =
        isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary =
        isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No sub-categories found',
              style: AppTextStyles.headingSm.copyWith(
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SUB-CATEGORY CARD ────────────────────────────────────
class _SubCategoryCard extends StatelessWidget {
  final String subCategoryName;
  final String description;
  final int docCount;
  final String yearCount;
  final String firstYear;
  final String lastYear;
  final VoidCallback onTap;

  const _SubCategoryCard({
    required this.subCategoryName,
    required this.description,
    required this.docCount,
    required this.yearCount,
    required this.firstYear,
    required this.lastYear,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSurface =
        isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight =
        isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final textPrimary =
        isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary;
    final textSecondary =
        isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
    final textTertiary =
        isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final brandPrimary =
        isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;
    final brandSurface =
        isDark ? AppTokens.darkBrandSurface : AppTokens.lightBrandSurface;
    final bgPage = isDark ? AppTokens.darkBgPage : AppTokens.lightBgPage;
    final shadowXs = isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowXs;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
              boxShadow: shadowXs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: title + arrow
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subCategoryName,
                            style: AppTextStyles.headingSm.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: AppTextStyles.bodyMd.copyWith(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: brandSurface,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(color: borderLight, width: 1),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: brandPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Divider(height: 1, color: borderLight),
                const SizedBox(height: 12),

                // Stats row
                Row(
                  children: [
                    Icon(Icons.description_outlined,
                        size: 14, color: textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      '$docCount Documents',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.schedule_outlined,
                        size: 14, color: textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      yearCount,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Year range box
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgPage,
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(color: borderLight, width: isDark ? 0.5 : 1.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EARLIEST',
                            style: AppTextStyles.labelSm.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: textTertiary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            firstYear,
                            style: AppTextStyles.headingSm.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: borderLight,
                      ),
                      Icon(Icons.trending_flat,
                          size: 16, color: textTertiary),
                      Container(
                        width: 1,
                        height: 24,
                        color: borderLight,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'LATEST',
                            style: AppTextStyles.labelSm.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: textTertiary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            lastYear,
                            style: AppTextStyles.headingSm.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
