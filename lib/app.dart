// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/core/constants/app_strings.dart';
import 'package:gda_vault_ai/core/router/app_router.dart';
import 'package:gda_vault_ai/core/theme/app_theme.dart';
import 'package:gda_vault_ai/providers/theme_provider.dart';
import 'package:gda_vault_ai/features/dashboard/widgets/floating_bubbles_overlay.dart';

class GdaVaultApp extends ConsumerWidget {
  const GdaVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return _GlobalOverlay(child: child!);
      },
    );
  }
}

class _GlobalOverlay extends StatelessWidget {
  final Widget child;
  const _GlobalOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    // We use a separate widget to get access to the router context
    return Stack(children: [child, _BubblesVisibilityWrapper()]);
  }
}

class _BubblesVisibilityWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppRouter.router.routerDelegate,
      builder: (context, child) {
        String location = '/';
        try {
          location = AppRouter
              .router
              .routerDelegate
              .currentConfiguration
              .last
              .matchedLocation;
        } catch (_) {}

        // Hide if we are on the chat tab or any full-screen modal like scanner/review
        final bool shouldHide =
            location.contains('/chat') ||
            location.contains('/scanner') ||
            location.contains('/review') ||
            location.contains('/select-category') ||
            location.contains('/pdf-preview') ||
            location.contains('/pdf');

        return FloatingBubblesOverlay(visible: !shouldHide);
      },
    );
  }
}
