import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF1A3A6B), AppColors.navyDark],
            ),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Icon(Icons.auto_awesome_rounded, size: 15, color: AppColors.gold),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: AppColors.divider, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDark.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (ctx, child) {
                  // Staggered bounce: each dot offset by 0.2
                  final offset = i * 0.2;
                  double animValue = (_controller.value - offset);
                  if (animValue < 0) animValue += 1.0;
                  
                  // Sine wave bounce
                  final bounce = sin(animValue * pi) * 5.0;
                  
                  return Transform.translate(
                    offset: Offset(0, -bounce),
                    child: Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.navyDark.withValues(alpha: 0.3 + (1.0 - animValue).clamp(0.0, 1.0) * 0.4),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}
