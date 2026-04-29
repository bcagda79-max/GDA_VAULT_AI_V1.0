import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/features/dashboard/tabs/chat_tab.dart';
import 'package:gda_vault_ai/features/dashboard/tabs/home_tab.dart';
import 'package:gda_vault_ai/features/dashboard/tabs/settings_tab.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/ai_chat_fab.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/gda_bottom_nav.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/home_app_bar.dart';

/// The main screen shell with a persistent bottom navigation bar.
class DashboardScreen extends ConsumerStatefulWidget {
  final Widget child;
  const DashboardScreen({super.key, required this.child});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard/add')) return 1;
    if (location.startsWith('/dashboard/chat')) return 2;
    if (location.startsWith('/dashboard/settings')) return 3;
    return 0;
  }

  void _onTabTapped(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/dashboard/add');
        break;
      case 2:
        context.go('/dashboard/chat');
        break;
      case 3:
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
            color: AppColors.charcoal.withOpacity(0.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(color: AppColors.charcoal.withOpacity(0.5)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = _getCurrentIndex(context);

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
        appBar: HomeAppBar(currentIndex: currentIndex),
        body: Stack(
          children: [
            widget.child,
            const Positioned(bottom: 75, right: 16, child: AiChatFab()),
          ],
        ),
        bottomNavigationBar: GdaBottomNav(
          currentIndex: currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
