// lib/features/dashboard/widgets/ai_chat_fab.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';

class AiChatFab extends StatelessWidget {
  const AiChatFab({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/dashboard/chat'),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withOpacity(0.3),
                width: 1.5,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 1500.ms,
                curve: Curves.easeInOut,
              ),

          // Main button
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A3A6B), AppColors.navyDark],
              ),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppColors.navyDark.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 22,
                color: AppColors.gold,
              ),
            ),
          ),

          // Green dot badge top-right
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.gdaGreenMid,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.navyDark, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
