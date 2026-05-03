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
  static const int _bubbleCount = 18; // Increased for more density

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
    final double size = _random.nextDouble() * 7 + 2; // More delicate sizes
    // Emerge from the AiChatFab position (bottom: 20, right: 16)
    // Relative to body height/width
    final double startX = 0.88 + (_random.nextDouble() * 0.08);
    final double startY = 0.90; // Start at the FAB center height

    // AI-themed color palette - Professional transparency
    final List<Color> palette = [
      AppColors.navyLight.withValues(alpha: 0.4),
      AppColors.gold.withValues(alpha: 0.25),
      AppColors.gdaGreenMid.withValues(alpha: 0.15),
      Colors.white.withValues(alpha: 0.15),
    ];

    return BubbleModel(
      x: startX,
      y: isInitial ? (0.6 + _random.nextDouble() * 0.3) : startY,
      size: size,
      speed: _random.nextDouble() * 0.0035 + 0.0015, // Slightly faster, dynamic
      drift: _random.nextDouble() * 0.003 - 0.0015,
      maxOpacity: _random.nextDouble() * 0.15 + 0.05,
      phase: _random.nextDouble() * math.pi * 2,
      scale: 0.0,
      color: palette[_random.nextInt(palette.length)],
      isBokeh: _random.nextDouble() > 0.65,
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
  Color color;
  bool isBokeh;

  BubbleModel({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.maxOpacity,
    required this.phase,
    required this.scale,
    required this.color,
    required this.isBokeh,
  });

  void update(math.Random random) {
    y -= speed;
    phase += 0.015;
    x += math.sin(phase) * 0.0008 + drift;

    // Smooth emergence
    if (scale < 1.0) scale += 0.03;

    // Reset when out of view (higher up or too far left/right)
    if (y < 0.6 || x < 0.0 || x > 1.0) {
      y = 0.90 + (random.nextDouble() * 0.02);
      x = 0.88 + (random.nextDouble() * 0.08);
      scale = 0.0;
      drift = random.nextDouble() * 0.003 - 0.0015;
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

      // Calculate opacity based on vertical position
      double verticalOpacity = 1.0;
      if (bubble.y < 0.8) verticalOpacity = (bubble.y - 0.6) / 0.2;
      verticalOpacity = verticalOpacity.clamp(0.0, 1.0);

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = bubble.isBokeh
            ? const MaskFilter.blur(BlurStyle.normal, 3.0)
            : null;

      final rect = Rect.fromCircle(center: Offset(dx, dy), radius: currentSize);

      final gradient = RadialGradient(
        colors: [
          bubble.color.withValues(
            alpha: bubble.maxOpacity * verticalOpacity * bubble.scale,
          ),
          bubble.color.withValues(alpha: 0.0),
        ],
        stops: const [0.2, 1.0],
      ).createShader(rect);

      paint.shader = gradient;
      canvas.drawCircle(Offset(dx, dy), currentSize, paint);

      // Add a tiny bright core for non-bokeh bubbles
      if (!bubble.isBokeh && bubble.scale > 0.5) {
        canvas.drawCircle(
          Offset(dx, dy),
          currentSize * 0.2,
          Paint()
            ..color = Colors.white.withValues(
              alpha: 0.4 * verticalOpacity * bubble.scale,
            ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
