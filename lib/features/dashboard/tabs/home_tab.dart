// lib/features/dashboard/tabs/home_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/features/add_document/add_document_modal.dart';
import 'package:intl/intl.dart';

/// The home tab of the dashboard, showing a summary and quick actions.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getFormattedDate() {
    return DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100, // space for FAB + bottom nav
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreetingCard(
            isDark,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.04, end: 0),
          const SizedBox(height: 16),
          _buildStatsRow(isDark)
              .animate()
              .fadeIn(delay: 150.ms, duration: 400.ms)
              .slideY(begin: 0.04, end: 0),
          const SizedBox(height: 20),
          Text(
            "Browse",
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal.withOpacity(0.4),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          _buildBigButton(
                context: context,
                title: "Categories",
                subtitle: "All document archives",
                badge: "1,284 files",
                icon: Icons.folder_open_rounded,
                onTap: () => context.push('/categories'),
                isPrimary: true,
              )
              .animate()
              .fadeIn(delay: 250.ms, duration: 350.ms)
              .slideX(begin: 0.03, end: 0),
          const SizedBox(height: 12),
          _buildBigButton(
                context: context,
                title: "Add New File",
                subtitle: "Add new record or document",
                icon: Icons.add_circle_outline_rounded,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const AddDocumentModal(),
                  );
                },
                isPrimary: true, // Matching categories style
              )
              .animate()
              .fadeIn(delay: 320.ms, duration: 350.ms)
              .slideX(begin: 0.03, end: 0),
        ],
      ),
    );
  }

  Widget _buildGreetingCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDark, Color(0xFF1E3A6E)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting().toUpperCase(),
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 11,
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Officer",
                  style: AppTextStyles.playfairDisplay.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Digital Archive Management",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 9,
                    color: AppColors.gold.withOpacity(0.7),
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _getFormattedDate(),
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Image.asset(
                  'assets/images/gda_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      "GDA",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            number: "1,284",
            label: "Documents",
            icon: Icons.folder_copy_rounded,
            iconColor: AppColors.catBoard,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            number: "70.2k",
            label: "Pages",
            icon: Icons.description_rounded,
            iconColor: AppColors.gdaGreen,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            number: "5",
            label: "Categories",
            icon: Icons.category_rounded,
            iconColor: AppColors.gold,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildBigButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    String? badge,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
    bool isDark = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppColors.navyDark, Color(0xFF1A3A6B)],
                )
              : null,
          color: isPrimary
              ? null
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(
                  color: AppColors.gdaGreen.withOpacity(0.4),
                  width: 1.5,
                ),
          boxShadow: [
            if (isPrimary)
              BoxShadow(
                color: AppColors.navyDark.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              )
            else
              BoxShadow(
                color: AppColors.gdaGreen.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isPrimary ? Colors.white.withOpacity(0.12) : null,
                    gradient: isPrimary
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.gdaGreen, Color(0xFF1A8A4A)],
                          ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: isPrimary ? 20 : 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isPrimary
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkText
                                  : AppColors.charcoal),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 10,
                        color: isPrimary
                            ? Colors.white.withOpacity(0.55)
                            : AppColors.charcoal.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                if (badge != null) const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isPrimary
                      ? Colors.white.withOpacity(0.6)
                      : AppColors.charcoal.withOpacity(0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _StatBox({
    required this.number,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            number,
            style:
                (isDark
                        ? AppTextStyles.statNumberDark
                        : AppTextStyles.statNumber)
                    .copyWith(fontSize: 20),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 9,
              color: (isDark ? AppColors.darkText : AppColors.charcoal)
                  .withOpacity(0.45),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
