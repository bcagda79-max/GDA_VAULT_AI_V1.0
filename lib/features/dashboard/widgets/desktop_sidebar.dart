import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class DesktopSidebar extends StatelessWidget {
  final String currentRoute;

  const DesktopSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.08),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 120;
                    return Row(
                      children: [
                        _SidebarLogo(
                          errorColor: isDark
                              ? Colors.white
                              : AppColors.charcoal,
                        ),
                        const SizedBox(width: 12),
                        if (!compact)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'GDA VAULT AI',
                                  style: AppTextStyles.dmSans.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.charcoal,
                                    letterSpacing: 0.8,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Galiyat Development Authority',
                                  style: AppTextStyles.dmSans.copyWith(
                                    fontSize: 8.5,
                                    color:
                                        (isDark
                                                ? Colors.white
                                                : AppColors.charcoal)
                                            .withValues(alpha: 0.65),
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Divider(height: 1, color: AppColors.gold.withValues(alpha: 0.18)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Column(
                  children: [
                    _SidebarItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      route: '/dashboard',
                      currentRoute: currentRoute,
                    ),
                    const SizedBox(height: 6),
                    _SidebarItem(
                      icon: Icons.folder_copy_rounded,
                      label: 'Categories',
                      route: '/categories',
                      currentRoute: currentRoute,
                    ),
                    const SizedBox(height: 6),
                    _SidebarItem(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Add Document',
                      route: '/dashboard/add',
                      currentRoute: currentRoute,
                    ),
                    const SizedBox(height: 6),
                    _SidebarItem(
                      icon: Icons.auto_awesome_rounded,
                      label: 'AI Chat',
                      route: '/dashboard/chat',
                      currentRoute: currentRoute,
                      badgeColor: AppColors.gold,
                    ),
                    const SizedBox(height: 6),
                    _SidebarItem(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      route: '/dashboard/settings',
                      currentRoute: currentRoute,
                    ),
                    const Spacer(),

                    _SidebarItem(
                      icon: Icons.logout_rounded,
                      label: 'Exit',
                      route: '',
                      currentRoute: '',
                      isDestructive: true,
                      onTap: () => _showExitDialog(context),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Exit GDA Vault AI',
          style: AppTextStyles.playfairDisplay.copyWith(
            color: Colors.white,
            fontSize: 17,
          ),
        ),
        content: Text(
          'Are you sure you want to exit the application?',
          style: AppTextStyles.dmSans.copyWith(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text(
              'Exit',
              style: AppTextStyles.dmSans.copyWith(
                color: AppColors.catPrivate,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final Color? badgeColor;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    this.badgeColor,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  bool get _isActive => _isActiveForRoute(widget.currentRoute, widget.route);

  // More precise active matching:
  // - For the main dashboard route ('/dashboard') only match exact path.
  // - For other routes, match exact or any child paths (e.g. '/categories' and '/categories/sub').
  bool _isActiveForRoute(String current, String route) {
    if (route.isEmpty) return false;
    if (route == '/dashboard') return current == '/dashboard';
    if (current == route) return true;
    return current.startsWith('$route/');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = widget.isDestructive
        ? AppColors.catPrivate.withValues(alpha: 0.75)
        : _isActive
        ? AppColors.gold
        : _hovered
        ? (isDark ? Colors.white : AppColors.charcoal)
        : (isDark
              ? Colors.white.withValues(alpha: 0.55)
              : AppColors.charcoal.withValues(alpha: 0.6));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap ?? () => context.go(widget.route),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isActive
                ? AppColors.gold.withValues(alpha: 0.12)
                : _hovered
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: _isActive
                ? Border.all(
                    color: AppColors.gold.withValues(alpha: 0.24),
                    width: 0.8,
                  )
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 100;
              return Row(
                children: [
                  if (_isActive)
                    Container(
                      width: 3,
                      height: 20,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  Stack(
                    children: [
                      Icon(widget.icon, size: 20, color: iconColor),
                      if (widget.badgeColor != null)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.badgeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  if (!compact)
                    Expanded(
                      child: Text(
                        widget.label,
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 13,
                          fontWeight: _isActive
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: _isActive
                              ? AppColors.gold
                              : widget.isDestructive
                              ? AppColors.catPrivate.withValues(alpha: 0.75)
                              : (isDark
                                    ? Colors.white.withValues(
                                        alpha: _hovered ? 0.92 : 0.72,
                                      )
                                    : AppColors.charcoal.withValues(
                                        alpha: _hovered ? 0.92 : 0.72,
                                      )),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  if (_isActive && !compact)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: AppColors.gold.withValues(alpha: 0.7),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  final Color errorColor;

  const _SidebarLogo({required this.errorColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
          width: 1.4,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/gda_logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              'GDA',
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: errorColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
