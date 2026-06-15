import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPage = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
    final textPrimary = isDark ? const Color(0xFFEBEBEB) : const Color(0xFF101828);
    final textSecondary = isDark ? const Color(0xFF8A8A8A) : const Color(0xFF475467);
    final brandPrimary = isDark ? const Color(0xFFEBEBEB) : const Color(0xFF141414);

    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D1010) : const Color(0xFFFEE4E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFFF04438),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Access Denied",
                style: AppTextStyles.headingLg.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Only Administrators have permission to upload or scan files in the vault. If you need access, please contact the system administrator.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLg.copyWith(
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 250,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go('/dashboard');
                  },
                  icon: const Icon(Icons.home_outlined),
                  label: const Text("Go to Home Screen"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandPrimary,
                    foregroundColor: isDark ? const Color(0xFF141414) : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppTextStyles.bodyLg.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
