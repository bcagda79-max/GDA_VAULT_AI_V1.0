import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/core/theme/app_theme.dart';
import 'package:gda_vault_ai/providers/theme_provider.dart';
import 'package:gda_vault_ai/core/constants/app_strings.dart';
import 'package:gda_vault_ai/core/router/app_router.dart';

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
        return child!;
      },
    );
  }
}
