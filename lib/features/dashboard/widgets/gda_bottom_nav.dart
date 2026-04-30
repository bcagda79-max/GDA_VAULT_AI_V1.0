// lib/features/dashboard/widgets/gda_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class GdaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GdaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkSurface : AppColors.navyDark;

    return Container(
      height: 85, // Increased height to accommodate curved design
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background with notch
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 65),
              painter: _BottomNavPainter(color: backgroundColor),
            ),
          ),
          // Nav Items
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 65,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, "Home"),
                  _buildNavItem(1, Icons.grid_view_rounded, "Categories"),
                  const SizedBox(width: 50), // Space for center button
                  _buildNavItem(3, Icons.smart_toy_rounded, "AI Chat"),
                  _buildNavItem(4, Icons.settings_rounded, "Settings"),
                ],
              ),
            ),
          ),
          // Center Elevated Button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF34B9FE), // Blue from reference image
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34B9FE).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = currentIndex == index;
    final color = isSelected ? const Color(0xFF34B9FE) : Colors.white.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65, // Reduced from 70
        child: Column(
          mainAxisSize: MainAxisSize.min, // Added min
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: isSelected ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 1.0 + (value * 0.12), // Slightly reduced scale
                  child: Icon(
                    icon,
                    size: 22, // Reduced from 24
                    color: Color.lerp(
                      Colors.white.withValues(alpha: 0.5),
                      const Color(0xFF34B9FE),
                      value,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 2), // Reduced from 4
            Text(
              label,
              maxLines: 1, // Ensure single line
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 9, // Reduced from 10
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavPainter extends CustomPainter {
  final Color color;
  _BottomNavPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, 0);
    
    // Left side
    path.lineTo(size.width * 0.35, 0);
    
    // Notch curve
    path.quadraticBezierTo(
      size.width * 0.40, 0,
      size.width * 0.42, 15,
    );
    path.arcToPoint(
      Offset(size.width * 0.58, 15),
      radius: const Radius.circular(35),
      clockwise: false,
    );
    path.quadraticBezierTo(
      size.width * 0.60, 0,
      size.width * 0.65, 0,
    );
    
    // Right side
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black, 5, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
