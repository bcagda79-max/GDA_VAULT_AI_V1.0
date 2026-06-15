import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/utils/responsive_helper.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/gda_bottom_nav.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/home_app_bar.dart';
import 'package:gda_vault_ai/widgets/gda_sidebar_item.dart';
import 'package:gda_vault_ai/providers/profile_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final Widget child;
  const DashboardScreen({super.key, required this.child});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/categories')) return 1;
    if (location.startsWith('/dashboard/add')) return 2;
    if (location.startsWith('/dashboard/chat') || location.contains('/chat')) return 3;
    if (location.startsWith('/dashboard/settings')) return 4;
    return 0;
  }

  void _onTabTapped(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/categories');
        break;
      case 2:
        context.go('/dashboard/add');
        break;
      case 3:
        context.go('/dashboard/chat');
        break;
      case 4:
        context.go('/dashboard/settings');
        break;
    }
  }

  void _showExitDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusLg)),
        title: Row(
          children: [
            Icon(
              Icons.exit_to_app_rounded,
              color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text("Exit App", style: AppTextStyles.headingMd.copyWith(
              color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
            )),
          ],
        ),
        content: Text(
          "Are you sure you want to exit GDA Vault AI?",
          style: AppTextStyles.bodyLg.copyWith(
            color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text(
              "Exit",
              style: TextStyle(
                color: isDark ? AppTokens.darkStatusError : AppTokens.lightStatusError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldHideBottomNav(BuildContext context) {
    final location = GoRouterState.of(context).uri.path.toLowerCase();
    return location.contains('/scanner') ||
        location.contains('/review') ||
        location.contains('/select-category') ||
        location.contains('/pdf-preview') ||
        location.contains('/pdf') ||
        location.contains('/chat');
  }

  bool _shouldHideAppBar(BuildContext context) {
    final location = GoRouterState.of(context).uri.path.toLowerCase();
    return _shouldHideBottomNav(context) ||
        location.startsWith('/categories') ||
        location.contains('/settings') ||
        location.startsWith('/dashboard/add') ||
        location.contains('/offline-documents') ||
        location.contains('/recent-documents');
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    final hideBottomNav = _shouldHideBottomNav(context);
    final isLargeScreen = ResponsiveHelper.isDesktop(context);
    final hideAppBar = _shouldHideAppBar(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentIndex != 0) {
          _onTabTapped(0);
        } else {
          _showExitDialog(context);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: hideAppBar
            ? null
            : HomeAppBar(
                currentIndex: currentIndex,
                isDesktop: isLargeScreen,
                leftInset: isLargeScreen ? 220.0 : 0,
              ),
        body: isLargeScreen
            ? Row(
                children: [
                  _buildDesktopNav(currentIndex),
                  Expanded(
                    child: widget.child,
                  ),
                ],
              )
            : widget.child,
        bottomNavigationBar: isLargeScreen || hideBottomNav
            ? null
            : GdaBottomNav(
                currentIndex: currentIndex, 
                onTap: _onTabTapped,
                isAdmin: ref.watch(isAdminProvider),
              ),
      ),
    );
  }

  Widget _buildDesktopNav(int currentIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTokens.darkBgSidebar : AppTokens.lightBgSidebar;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);
    final navLabelColor = isDark ? AppTokens.darkTextSidebar : AppTokens.lightTextSidebar;

    return Container(
      width: 220,
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 12),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Image.asset(
                'assets/images/gda_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.business,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GDA VAULT AI',
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Galiyat Development Authority',
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppTokens.lightTextSidebar,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            height: 1,
            color: dividerColor,
          ),
          
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 12),
            child: Text(
              'NAVIGATION',
              style: AppTextStyles.labelSm.copyWith(
                color: navLabelColor,
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GdaSidebarItem(
                    label: 'Home',
                    icon: Icons.home_rounded,
                    selected: currentIndex == 0,
                    onTap: () => _onTabTapped(0),
                  ),
                  const SizedBox(height: 4),
                  GdaSidebarItem(
                    label: 'Categories',
                    icon: Icons.folder_copy_rounded,
                    selected: currentIndex == 1,
                    onTap: () => _onTabTapped(1),
                  ),
                  const SizedBox(height: 4),
                  GdaSidebarItem(
                    label: 'Add Document',
                    icon: ref.watch(isAdminProvider) ? Icons.add_circle_outline_rounded : Icons.lock_outline,
                    selected: currentIndex == 2,
                    onTap: () {
                      if (!ref.read(isAdminProvider)) {
                        context.go('/access-denied');
                        return;
                      }
                      _onTabTapped(2);
                    },
                  ),
                  const SizedBox(height: 4),
                  GdaSidebarItem(
                    label: 'AI Chat',
                    icon: Icons.auto_awesome_rounded,
                    selected: currentIndex == 3,
                    onTap: () => _onTabTapped(3),
                  ),
                  const SizedBox(height: 4),
                  GdaSidebarItem(
                    label: 'Settings',
                    icon: Icons.settings_rounded,
                    selected: currentIndex == 4,
                    onTap: () => _onTabTapped(4),
                  ),
                ],
              ),
            ),
          ),
          
          Container(
            height: 1,
            color: dividerColor,
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _HoverExitButton(),
                Text(
                  'v1.0.0',
                  style: AppTextStyles.caption.copyWith(color: navLabelColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverExitButton extends StatefulWidget {
  const _HoverExitButton();

  @override
  State<_HoverExitButton> createState() => _HoverExitButtonState();
}

class _HoverExitButtonState extends State<_HoverExitButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = const Color(0xFFEF4444);
    final hoverColor = const Color(0xFFF87171);
    final currentColor = _isHovered ? hoverColor : baseColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final parentState = context.findAncestorStateOfType<_DashboardScreenState>();
          parentState?._showExitDialog(context);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered ? baseColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              AnimatedTheme(
                data: Theme.of(context).copyWith(
                  iconTheme: IconThemeData(color: currentColor),
                ),
                child: Icon(Icons.logout_rounded, size: 18, color: currentColor),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: AppTextStyles.labelLg.copyWith(
                  color: currentColor,
                  fontWeight: FontWeight.w600,
                ),
                child: const Text('Exit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

