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

    final bgSurface = isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight = isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final textTertiary = isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final shadowXs = isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowXs;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderLight),
            boxShadow: shadowXs,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/images/gda_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            border: Border.all(color: borderLight),
            boxShadow: shadowXs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (ctx, child) {
                  final offset = i * 0.2;
                  double animValue = (_controller.value - offset);
                  if (animValue < 0) animValue += 1.0;

                  // Scale pulse 0.5 -> 1.0
                  final scale = 0.5 + (sin(animValue * pi) * 0.5).clamp(0.0, 0.5);

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: textTertiary,
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

