// lib/features/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_spacing.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

/// A splash screen that appears when the app is launched, with animations.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        context.go('/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final animationsDisabled = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  const Color(0xFF1A3A6B).withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.08),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/gda_logo.png',
                        width: 140,
                        height: 140,
                      ),
                    )
                    .animate(target: animationsDisabled ? 0 : 1)
                    .fadeIn(duration: 800.ms)
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                      "GDA Vault AI",
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    )
                    .animate(target: animationsDisabled ? 0 : 1)
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.5, end: 0),
                const SizedBox(height: AppSpacing.sm),
                Text(
                      "GALIYAT DEVELOPMENT AUTHORITY",
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
                        letterSpacing: 2.5,
                      ),
                    )
                    .animate(target: animationsDisabled ? 0 : 1)
                    .fadeIn(delay: 700.ms, duration: 500.ms),
                const SizedBox(height: AppSpacing.xl),
                Container(width: 48, height: 1.5, color: AppColors.gold)
                    .animate(target: animationsDisabled ? 0 : 1)
                    .custom(
                      delay: 900.ms,
                      duration: 400.ms,
                      builder: (context, value, child) => Container(
                        width: 48 * value,
                        height: 1.5,
                        color: AppColors.gold,
                      ),
                    ),
                const SizedBox(height: AppSpacing.md),
                Text(
                      "Official Document Archive System",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    )
                    .animate(target: animationsDisabled ? 0 : 1)
                    .fadeIn(delay: 1100.ms, duration: 400.ms),
              ],
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(
                      target: animationsDisabled ? 0 : 1,
                      delay: (1200 + index * 200).ms,
                      onPlay: (controller) => controller.repeat(),
                    )
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      duration: 600.ms,
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.2, 1.2),
                      end: const Offset(0.8, 0.8),
                      duration: 600.ms,
                      curve: Curves.easeInOut,
                    );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
