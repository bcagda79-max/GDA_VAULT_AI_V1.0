// lib/features/add_document/add_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';

/// The hub for adding new documents via scan or file import.
class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

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

        // Navigate to category selector with actual file data
        context.push(
          '/dashboard/add/select-category',
          extra: {
            'source': 'file',
            'fileName': file.name,
            'fileSize': file.size,
            'filePath': file.path,
            'pageCount':
                45, // Default estimate (would need PDF parsing for accuracy)
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Column(
          children: [
            Text(
              "Add Document",
              style: AppTextStyles.playfairDisplay.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Scan or import a file",
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 9,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeroBanner(
              width,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.03, end: 0),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 4, bottom: 8),
              child: Text(
                "Choose Method",
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal.withOpacity(0.45),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMethodCard(
                      context: context,
                      isDark: isDark,
                      title: "Scan Document",
                      subtitle: "Use camera to scan physical documents",
                      icon: Icons.document_scanner_rounded,
                      gradient: const [AppColors.catBoard, Color(0xFF1A3A6B)],
                      onTap: () => context.push('/dashboard/add/scanner'),
                      isRecommended: true,
                      features: const [
                        _Feature(Icons.auto_fix_high, "Auto Edge Detect"),
                        _Feature(Icons.brightness_6, "Auto Enhance"),
                        _Feature(Icons.filter_none, "Multi-Page"),
                        _Feature(Icons.picture_as_pdf, "Export PDF"),
                      ],
                      actionLabel: "Open Scanner",
                    )
                    .animate(delay: 150.ms)
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: 0.04, end: 0),
                AppSpacing.vertical(14),
                _buildFileImportCard(
                      context: context,
                      isDark: isDark,
                      onTap: () => _pickPDFFile(context),
                    )
                    .animate(delay: 250.ms)
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: 0.04, end: 0),
                AppSpacing.vertical(32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(double width) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 150,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDark, Color(0xFF1A3A6B), Color(0xFF0D2B5E)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.25), width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.upload_file,
                              size: 12,
                              color: AppColors.gold,
                            ),
                            AppSpacing.horizontal(6),
                            Text(
                              "DOCUMENT UPLOAD",
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: 9,
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.vertical(10),
                      Text(
                        "Add New Document",
                        style: AppTextStyles.playfairDisplay.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      AppSpacing.vertical(6),
                      Text(
                        "Scan physical documents or\nimport PDF files from device",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.55),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 32,
                      color: Colors.white.withOpacity(0.7),
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

  Widget _buildMethodCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
    bool isRecommended = false,
    required List<_Feature> features,
    required String actionLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(icon, size: 28, color: Colors.white),
                      ),
                    ),
                    AppSpacing.horizontal(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              if (isRecommended)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.gdaGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "RECOMMENDED",
                                    style: AppTextStyles.dmSans.copyWith(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gdaGreen,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          AppSpacing.vertical(4),
                          Text(
                            subtitle,
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.charcoal.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.vertical(16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: features
                        .map((f) => _buildFeaturePill(f.icon, f.text))
                        .toList(),
                  ),
                ),
                AppSpacing.vertical(16),
                Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 18, color: Colors.white),
                        AppSpacing.horizontal(8),
                        Text(
                          actionLabel,
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.catBoard.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.catBoard.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.catBoard.withOpacity(0.7)),
          AppSpacing.horizontal(4),
          Text(
            text,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 10,
              color: AppColors.charcoal.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileImportCard({
    required BuildContext context,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gdaGreen, Color(0xFF1A8A4A)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gdaGreen.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.upload_file_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    AppSpacing.horizontal(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Choose from Device",
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.charcoal,
                            ),
                          ),
                          AppSpacing.vertical(4),
                          Text(
                            "Import existing PDF files",
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.charcoal.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.vertical(16),
                Row(
                  children: [
                    _buildInfoBadge(
                      icon: Icons.picture_as_pdf,
                      color: AppColors.gdaGreen,
                      title: "PDF Files Only",
                      subtitle: "Maximum 50 MB per file",
                      isDark: isDark,
                    ),
                    AppSpacing.horizontal(12),
                    _buildInfoBadge(
                      icon: Icons.security_rounded,
                      color: AppColors.gold,
                      title: "Secure Upload",
                      subtitle: "Encrypted transfer",
                      isDark: isDark,
                    ),
                  ],
                ),
                AppSpacing.vertical(16),
                Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.gdaGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.folder_open_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        AppSpacing.horizontal(8),
                        Text(
                          "Browse Files",
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            AppSpacing.horizontal(6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkText : AppColors.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 8,
                      color: isDark
                          ? Colors.white.withOpacity(0.45)
                          : AppColors.charcoal.withOpacity(0.45),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUploadsHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Recent Uploads",
            style: AppTextStyles.playfairDisplay.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.charcoal,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              "See All",
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 12,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUploadsList(bool isDark) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.catBoard,
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppSpacing.horizontal(6),
                    Text(
                      "202${4 - index}",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${index + 1}d ago",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 9,
                        color: AppColors.charcoal.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vertical(8),
                Text(
                  "Archive_Doc_00${index + 1}.pdf",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 11,
                    color: isDark ? AppColors.darkText : AppColors.charcoal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 11,
                      color: AppColors.catBoard,
                    ),
                    AppSpacing.horizontal(4),
                    Text(
                      "${12 + index * 5}pp",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 9,
                        color: AppColors.charcoal.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ).animate(delay: 350.ms).fadeIn(duration: 400.ms),
    );
  }
}

class _Feature {
  final IconData icon;
  final String text;
  const _Feature(this.icon, this.text);
}
