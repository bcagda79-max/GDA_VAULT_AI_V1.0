import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';

class FloatingBubblesOverlay extends StatefulWidget {
  final bool visible;
  const FloatingBubblesOverlay({super.key, required this.visible});

  @override
  State<FloatingBubblesOverlay> createState() => _FloatingBubblesOverlayState();
}

class _FloatingBubblesOverlayState extends State<FloatingBubblesOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<BubbleModel> _bubbles = [];
  final math.Random _random = math.Random();
  static const int _bubbleCount = 12;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            if (mounted) setState(() {});
          });

    _initializeBubbles();
    _controller.repeat();
  }

  void _initializeBubbles() {
    for (int i = 0; i < _bubbleCount; i++) {
      _bubbles.add(_createBubble(isInitial: true));
    }
  }

  BubbleModel _createBubble({bool isInitial = false}) {
    final double size =
        _random.nextDouble() * 6 + 3; // Slightly larger bubbles (3 to 9)
    // Emerge from the bottom right area where the FAB is located
    final double startX = 0.82 + (_random.nextDouble() * 0.15);
    final double startY = 0.82 + (_random.nextDouble() * 0.15);

    return BubbleModel(
      x: startX,
      y: isInitial ? (0.8 + _random.nextDouble() * 0.2) : startY,
      size: size,
      speed: _random.nextDouble() * 0.002 + 0.001, // Faster movement
      drift: _random.nextDouble() * 0.002 - 0.001,
      maxOpacity: _random.nextDouble() * 0.4 + 0.2,
      phase: _random.nextDouble() * math.pi * 2,
      scale: 0.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: widget.visible
          ? IgnorePointer(
              child: CustomPaint(
                painter: BubblesPainter(bubbles: _bubbles, random: _random),
                size: Size.infinite,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class BubbleModel {
  double x;
  double y;
  double size;
  double speed;
  double drift;
  double maxOpacity;
  double phase;
  double scale;

  BubbleModel({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.maxOpacity,
    required this.phase,
    required this.scale,
  });

  void update(math.Random random) {
    y -= speed;
    phase += 0.02;
    x += math.sin(phase) * 0.001 + drift;

    // Smooth emergence
    if (scale < 1.0) scale += 0.05;

    // Disappear quickly as they go up
    if (y < 0.6) {
      y = 0.9; // Reset to FAB area
      x = 0.85 + (random.nextDouble() * 0.1);
      scale = 0.0;
    }
  }
}

class BubblesPainter extends CustomPainter {
  final List<BubbleModel> bubbles;
  final math.Random random;

  BubblesPainter({required this.bubbles, required this.random});

  @override
  void paint(Canvas canvas, Size size) {
    for (var bubble in bubbles) {
      bubble.update(random);

      final double dx = bubble.x * size.width;
      final double dy = bubble.y * size.height;
      final double currentSize = bubble.size * bubble.scale;

      // Calculate opacity based on vertical position (disappear quickly)
      double verticalOpacity = 1.0;
      if (bubble.y < 0.8) verticalOpacity = (bubble.y - 0.6) / 0.2;
      verticalOpacity = verticalOpacity.clamp(0.0, 1.0);

      final paint = Paint()..style = PaintingStyle.fill;

      final rect = Rect.fromCircle(center: Offset(dx, dy), radius: currentSize);

      final gradient = RadialGradient(
        colors: [
          AppColors.navyDark.withValues(
            alpha: bubble.maxOpacity * verticalOpacity * bubble.scale,
          ),
          AppColors.navyDark.withValues(alpha: 0.0),
        ],
      ).createShader(rect);

      paint.shader = gradient;
      canvas.drawCircle(Offset(dx, dy), currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
