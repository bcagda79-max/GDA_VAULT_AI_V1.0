// lib/features/dashboard/widgets/ai_chat_fab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';

class AiChatFab extends StatelessWidget {
  const AiChatFab({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.go('/dashboard/chat');
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated outer glow
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.15),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              )
              .fadeOut(begin: 0.5),

          // Main FAB Container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.navyDark,
                  AppColors.navyMid,
                  Color(0xFF2A4A8B),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDark.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner highlight
                Positioned(
                  top: 4,
                  left: 8,
                  child: Container(
                    width: 20,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.all(Radius.elliptical(20, 10)),
                    ),
                  ),
                ),
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.gold,
                  size: 28,
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 3000.ms,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -4,
                end: 4,
                duration: 2500.ms,
                curve: Curves.easeInOutSine,
              ),
        ],
      ),
    );
  }
}
