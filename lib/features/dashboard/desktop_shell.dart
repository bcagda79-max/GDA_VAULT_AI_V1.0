import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/utils/responsive_helper.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/desktop_sidebar.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/home_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class DesktopShell extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const DesktopShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use the actual URI path from context for more reliable sub-route detection
    final effectiveRoute = GoRouterState.of(context).uri.path;

    // Robust check: Only show if route is exactly '/dashboard' or '/'
    // Hide if it contains sub-paths like /dashboard/recent-documents
    final showHomeAppBar =
        effectiveRoute == '/dashboard' ||
        effectiveRoute == '/dashboard/' ||
        effectiveRoute == '/';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
      body: Row(
        children: [
          DesktopSidebar(currentRoute: effectiveRoute),
          Expanded(
            child: Column(
              children: [
                if (showHomeAppBar)
                  const HomeAppBar(currentIndex: 0, isDesktop: true),
                Expanded(
                  child: Container(
                    color: isDark ? AppColors.darkBg : AppColors.paper,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.02, 0.0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(effectiveRoute),
                        child: child,
                      ),
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
}
