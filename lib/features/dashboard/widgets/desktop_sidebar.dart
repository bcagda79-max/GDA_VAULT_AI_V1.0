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
    return Container(
      width: 270,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B3E), Color(0xFF1A237E)],
        ),
        border: Border(right: BorderSide(color: Color(0xFF2A3F7E), width: 1)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0A1628),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF2A3F7E), width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFC5A059),
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/gda_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                                  child: Text(
                                    'GDA',
                                    style: AppTextStyles.dmSans.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFC5A059),
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'GDA VAULT AI',
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFC5A059),
                                letterSpacing: 2.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Galiyat Development Authority',
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: 10.5,
                                color: const Color(0xFF6B82AA),
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    width: 40,
                    color: const Color(0xFFC5A059).withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        top: 20,
                        bottom: 6,
                      ),
                      child: Text(
                        'NAVIGATION',
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 9.5,
                          color: const Color(0xFF4A6394),
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Column(
                        children: [
                          _SidebarItem(
                            icon: Icons.grid_view_rounded,
                            label: 'Home',
                            route: '/dashboard',
                            currentRoute: currentRoute,
                          ),
                          _SidebarItem(
                            icon: Icons.folder_outlined,
                            label: 'Categories',
                            route: '/categories',
                            currentRoute: currentRoute,
                          ),
                          _SidebarItem(
                            icon: Icons.note_add_outlined,
                            label: 'Add Document',
                            route: '/dashboard/add',
                            currentRoute: currentRoute,
                          ),
                          _SidebarItem(
                            icon: Icons.auto_awesome_outlined,
                            label: 'AI Chat',
                            route: '/dashboard/chat',
                            currentRoute: currentRoute,
                          ),
                          const Divider(
                            color: Color(0xFF1E3260),
                            thickness: 0.8,
                            indent: 20,
                            endIndent: 20,
                            height: 20,
                          ),
                          _SidebarItem(
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                            route: '/dashboard/settings',
                            currentRoute: currentRoute,
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      color: Color(0xFF1E3260),
                      thickness: 0.8,
                      indent: 20,
                      endIndent: 20,
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Center(
                        child: Text(
                          'GDA VAULT AI  V1.0',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 9,
                            color: const Color(0xFF2D4070),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: _SidebarItem(
                        icon: Icons.logout_rounded,
                        label: 'EXIT',
                        route: '',
                        currentRoute: '',
                        isDestructive: true,
                        onTap: () => _showExitDialog(context),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
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
  final bool isDestructive;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
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
    final isHovered = _hovered;
    final isExit = widget.isDestructive;
    final activeColor = const Color(0xFFC5A059);
    final hoverBg = const Color(0xFF0F2040);
    final activeBg = const Color(0xFF162B4F);
    final inactiveIconColor = const Color(0xFF7B93C8);
    final inactiveTextColor = const Color(0xFF7B93C8);
    final hoverIconColor = const Color(0xFFB0C4E8);
    final hoverTextColor = const Color(0xFFD0DCF0);
    final exitColor = const Color(0xFFE57373);

    final backgroundColor = isExit
        ? (isHovered ? const Color(0xFF1A0A0A) : Colors.transparent)
        : _isActive
        ? activeBg
        : isHovered
        ? hoverBg
        : Colors.transparent;

    final iconColor = isExit
        ? exitColor
        : _isActive
        ? activeColor
        : isHovered
        ? hoverIconColor
        : inactiveIconColor;

    final textColor = isExit
        ? exitColor
        : _isActive
        ? Colors.white
        : isHovered
        ? hoverTextColor
        : inactiveTextColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap ?? () => context.go(widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              left: BorderSide(
                color: _isActive ? activeColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(widget.icon, size: 18, color: iconColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.label.toUpperCase(),
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 12.5,
                      fontWeight: _isActive ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                      letterSpacing: 1.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
