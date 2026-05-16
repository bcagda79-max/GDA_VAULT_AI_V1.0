// ignore_for_file: unused_import, curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/core/utils/responsive_helper.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/ai_chat_fab.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/floating_bubbles_overlay.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/gda_bottom_nav.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/home_app_bar.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/desktop_nav_item.dart';

/// The main screen shell with a persistent bottom navigation bar.
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
    if (location.startsWith('/dashboard/chat') || location.contains('/chat'))
      return 3;
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.exit_to_app_rounded,
              color: AppColors.navyDark,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text("Exit App", style: AppTextStyles.titleMedium),
          ],
        ),
        content: Text(
          "Are you sure you want to exit GDA Vault AI?",
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.charcoal.withValues(alpha: 0.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: AppColors.charcoal.withValues(alpha: 0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text(
              "Exit",
              style: TextStyle(
                color: AppColors.catPrivate,
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
    // Strictly hide on scanner, review, category selection, PDF viewer flow, and AI Chat
    return location.contains('/scanner') ||
        location.contains('/review') ||
        location.contains('/select-category') ||
        location.contains('/pdf-preview') ||
        location.contains('/pdf') ||
        location.contains('/chat');
  }

  bool _shouldHideAppBar(BuildContext context) {
    final location = GoRouterState.of(context).uri.path.toLowerCase();
    // Hide dashboard app bar on sub-screens or when bottom nav is hidden
    return _shouldHideBottomNav(context) ||
        location.startsWith('/categories') ||
        location.contains('/settings') ||
        location.startsWith('/dashboard/add') ||
        location.contains('/offline-documents') ||
        location.contains('/recent-documents');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = _getCurrentIndex(context);
    final hideBottomNav = _shouldHideBottomNav(context);
    final isLargeScreen = ResponsiveHelper.isDesktop(context);
    final hideAppBar = _shouldHideAppBar(context);
    // Responsive FAB positioning: adjust for larger screens
    final fabBottom = isLargeScreen ? 24.0 : 20.0;
    final fabRight = isLargeScreen ? 32.0 : 16.0;

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
        backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
        appBar: hideAppBar
            ? null
            : HomeAppBar(
                currentIndex: currentIndex,
                isDesktop: isLargeScreen,
                leftInset: isLargeScreen
                    ? ResponsiveHelper.sidebarWidth(context)
                    : 0,
              ),
        // For large screens, show a permanent left navigation panel instead of bottom nav
        body: isLargeScreen
            ? Row(
                children: [
                  // Desktop navigation drawer (permanent)
                  // nav width now 280
                  _buildDesktopNav(currentIndex, isDark),
                  // Main content
                  Expanded(
                    child: Stack(
                      children: [
                        widget.child,
                        if (!hideBottomNav &&
                            currentIndex != 1 &&
                            currentIndex != 3 &&
                            currentIndex != 4)
                          Positioned(
                            bottom: fabBottom,
                            right: fabRight,
                            child: const AiChatFab(),
                          ),
                      ],
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  widget.child,
                  if (!hideBottomNav &&
                      currentIndex != 1 && // Hide on Categories tab
                      currentIndex != 3 && // Hide on Chat tab
                      currentIndex != 4) // Hide on Settings tab
                    Positioned(
                      bottom: fabBottom,
                      right: fabRight,
                      child: const AiChatFab(),
                    ),
                ],
              ),
        bottomNavigationBar: isLargeScreen || hideBottomNav
            ? null
            : GdaBottomNav(currentIndex: currentIndex, onTap: _onTabTapped),
      ),
    );
  }

  Widget _buildDesktopNav(int currentIndex, bool isDark) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryBlue,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset('assets/images/gda_logo.png'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GDA VAULT AI', style: AppTextStyles.titleMedium),
                      Text(
                        'Galiyat Development Authority',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.charcoal.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Navigation items
          DesktopNavItem(
            label: 'Home',
            icon: Icons.home_rounded,
            selected: currentIndex == 0,
            onTap: () => _onTabTapped(0),
          ),
          DesktopNavItem(
            label: 'Categories',
            icon: Icons.folder_open_rounded,
            selected: currentIndex == 1,
            onTap: () => _onTabTapped(1),
          ),
          DesktopNavItem(
            label: 'Add',
            icon: Icons.add_circle_outline_rounded,
            selected: currentIndex == 2,
            onTap: () => _onTabTapped(2),
          ),
          DesktopNavItem(
            label: 'AI Chat',
            icon: Icons.auto_awesome_rounded,
            selected: currentIndex == 3,
            onTap: () => _onTabTapped(3),
          ),
          DesktopNavItem(
            label: 'Settings',
            icon: Icons.settings_rounded,
            selected: currentIndex == 4,
            onTap: () => _onTabTapped(4),
          ),
          const Spacer(),
          // Sign out / footer action placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              onPressed: () => _showExitDialog(context),
              icon: const Icon(Icons.exit_to_app_rounded),
              label: const Text('Exit'),
            ),
          ),
        ],
      ),
    );
  }
}
