import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class DesktopSidebar extends StatefulWidget {
  final String currentRoute;

  const DesktopSidebar({super.key, required this.currentRoute});

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  bool _isCollapsed = false;
  bool _isHoveringToggle = false;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.grid_view_rounded, 'label': 'Home', 'route': '/dashboard'},
    {
      'icon': Icons.folder_outlined,
      'label': 'Categories',
      'route': '/categories',
    },
    {
      'icon': Icons.note_add_outlined,
      'label': 'Add Document',
      'route': '/dashboard/add',
    },
    {
      'icon': Icons.auto_awesome_outlined,
      'label': 'AI Chat',
      'route': '/dashboard/chat',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuart,
      width: _isCollapsed ? 76 : 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF060F1E), Color(0xFF0D1B3E), Color(0xFF111D42)],
          stops: [0.0, 0.5, 1.0],
        ),
        border: const Border(
          right: BorderSide(color: Color(0xFF1E2D56), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionLabel(),
                    const SizedBox(height: 8),
                    _buildNavItems(),
                    _buildDivider(),
                    _buildSettingsItem(),
                  ],
                ),
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isCollapsed ? 0 : 20,
        vertical: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF060F1E),
        border: Border(bottom: BorderSide(color: Color(0xFF1E2D56), width: 1)),
      ),
      child: Column(
        key: const ValueKey('sidebar_header_column'),
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle button at the very top
          _buildToggleButton(),
          SizedBox(height: _isCollapsed ? 16 : 24),

          // Logo Section
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.95, end: 1.0),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Image.asset(
              'assets/images/gda_logo.png',
              width: _isCollapsed ? 42 : 64,
              height: _isCollapsed ? 42 : 64,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => CircleAvatar(
                radius: _isCollapsed ? 21 : 32,
                backgroundColor: Colors.transparent,
                child: Text(
                  _isCollapsed ? 'G' : 'GDA',
                  style: TextStyle(
                    color: const Color(0xFFC5A059),
                    fontSize: _isCollapsed ? 12 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),

          // Text Labels (Animated appearance)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isCollapsed ? 0 : 110,
            child: ClipRect(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isCollapsed ? 0 : 1,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'GDA VAULT AI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFC5A059),
                          letterSpacing: 2.5,
                          fontFamily: 'DMSans',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Galiyat Development Authority',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF5A7BAA),
                          letterSpacing: 0.5,
                          fontFamily: 'DMSans',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildHeaderDivider(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFF1E2D56))),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Color(0xFFC5A059),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFF1E2D56))),
      ],
    );
  }

  Widget _buildToggleButton() {
    return Align(
      alignment: _isCollapsed ? Alignment.center : Alignment.centerRight,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHoveringToggle = true),
        onExit: (_) => setState(() => _isHoveringToggle = false),
        child: GestureDetector(
          onTap: () => setState(() => _isCollapsed = !_isCollapsed),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _isHoveringToggle
                  ? const Color(0xFFC5A059).withOpacity(0.15)
                  : const Color(0xFF060F1E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(
                  0xFFC5A059,
                ).withOpacity(_isHoveringToggle ? 0.6 : 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                _isCollapsed
                    ? Icons.view_sidebar_rounded
                    : Icons.view_sidebar_outlined,
                size: 18,
                color: const Color(0xFFC5A059),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel() {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.only(left: _isCollapsed ? 0 : 20, top: 20, bottom: 6),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _isCollapsed
            ? Center(
                child: Container(
                  width: 24,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3260),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              )
            : const Text(
                'NAVIGATION',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3D5580),
                ),
              ),
      ),
    );
  }

  Widget _buildNavItems() {
    return Column(
      children: _navItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildAnimatedSidebarItem(item, index);
      }).toList(),
    );
  }

  Widget _buildAnimatedSidebarItem(Map<String, dynamic> item, int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${item['route']}_${_isCollapsed}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(_isCollapsed ? 0 : (1 - value) * -10, 0),
            child: child,
          ),
        );
      },
      child: _SidebarItem(
        icon: item['icon'],
        label: item['label'],
        route: item['route'],
        currentRoute: widget.currentRoute,
        isCollapsed: _isCollapsed,
      ),
    );
  }

  Widget _buildDivider() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
        horizontal: _isCollapsed ? 16 : 20,
        vertical: 16,
      ),
      height: 1,
      color: const Color(0xFF1E3260),
    );
  }

  Widget _buildSettingsItem() {
    return _SidebarItem(
      icon: Icons.settings_outlined,
      label: 'Settings',
      route: '/dashboard/settings',
      currentRoute: widget.currentRoute,
      isCollapsed: _isCollapsed,
    );
  }

  Widget _buildBottomSection() {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.only(bottom: 24, top: 12, left: _isCollapsed ? 0 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SidebarItem(
            icon: Icons.logout_rounded,
            label: 'EXIT',
            route: '',
            currentRoute: '',
            isDestructive: true,
            onTap: () => _showExitDialog(context),
            isCollapsed: _isCollapsed,
          ),
        ],
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
  final bool isCollapsed;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    this.isDestructive = false,
    this.onTap,
    required this.isCollapsed,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  bool get _isActive => _isActiveForRoute(widget.currentRoute, widget.route);

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
    final activeBg = const Color(0xFF0E2040);
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

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuart,
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          left: BorderSide(
            color: _isActive ? activeColor : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: widget.isCollapsed
          ? Center(child: Icon(widget.icon, size: 20, color: iconColor))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Row(
                children: [
                  const SizedBox(width: 20 - 3), // compensate for left border
                  Icon(widget.icon, size: 18, color: iconColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: textColor,
                        letterSpacing: 1.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (_isActive) ...[
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5A059),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC5A059).withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ],
              ),
            ),
    );

    if (widget.isCollapsed) {
      content = Tooltip(
        message: widget.label,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B3E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFC5A059).withOpacity(0.3)),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        child: content,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap ?? () => context.go(widget.route),
        child: content,
      ),
    );
  }
}
