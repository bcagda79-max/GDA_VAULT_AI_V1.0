import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/utils/responsive_helper.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/desktop_sidebar.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/home_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    final sidebarWidth = ResponsiveHelper.sidebarWidth(context);
    final showHomeAppBar = currentRoute == '/dashboard';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
      body: Row(
        children: [
          SizedBox(
            width: sidebarWidth,
            child: DesktopSidebar(currentRoute: currentRoute),
          ),
          Expanded(
            child: Column(
              children: [
                if (showHomeAppBar) const HomeAppBar(currentIndex: 0),
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
                        key: ValueKey(currentRoute),
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
