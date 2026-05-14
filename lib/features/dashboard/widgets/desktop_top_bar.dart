import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/utils/responsive_helper.dart';
import 'package:gda_vault_ai/providers/theme_provider.dart';

class DesktopTopBar extends ConsumerWidget {
  final String currentRoute;

  const DesktopTopBar({super.key, required this.currentRoute});

  String _getPageTitle() {
    if (currentRoute.contains('chat')) return 'AI Chat';
    if (currentRoute.contains('categories')) return 'Categories';
    if (currentRoute.contains('settings')) return 'Settings';
    if (currentRoute.contains('add')) return 'Add Document';
    return 'Dashboard';
  }

  String _getPageSubtitle() {
    if (currentRoute.contains('chat'))
      return 'Ask questions about GDA archives';
    if (currentRoute.contains('categories'))
      return 'Browse all document categories';
    if (currentRoute.contains('settings')) return 'Application preferences';
    if (currentRoute.contains('add')) return 'Upload or scan new documents';
    return 'Galiyat Development Authority Archive';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = ResponsiveHelper.contentPadding(context);
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: padding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.divider,
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SelectableText(
                _getPageTitle(),
                style: AppTextStyles.playfairDisplay.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.charcoal,
                ),
              ),
              Text(
                _getPageSubtitle(),
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 11,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : AppColors.charcoal.withValues(alpha: 0.52),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.navyDark.withValues(alpha: isDark ? 0.4 : 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.navyDark.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppColors.navyDark.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  dateStr.toUpperCase(),
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.58)
                        : AppColors.navyDark.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Keep only theme toggle on desktop; remove search & notifications for cleaner desktop chrome
          _TopBarIconBtn(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: 'Toggle theme',
            onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _TopBarIconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDark;

  const _TopBarIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_TopBarIconBtn> createState() => _TopBarIconBtnState();
}

class _TopBarIconBtnState extends State<_TopBarIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hovered
                  ? (widget.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.navyDark.withValues(alpha: 0.06))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.65)
                  : AppColors.charcoal.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }
}
