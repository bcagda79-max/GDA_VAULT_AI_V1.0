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
      child:
          Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.navyDark, Color(0xFF2A4A8B)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyDark.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -3,
                end: 3,
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),
    );
  }
}
