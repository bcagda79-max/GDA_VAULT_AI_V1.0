// lib/features/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_strings.dart';

/// A login screen for user authentication.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.loginTitle)),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/dashboard/categories');
          },
          child: const Text(AppStrings.loginButton),
        ),
      ),
    );
  }
}
