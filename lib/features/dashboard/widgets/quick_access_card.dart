import 'package:flutter/material.dart';

class QuickAccessCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const QuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<QuickAccessCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF);
    final borderColor =
        widget.isDark ? const Color(0xFF272727) : const Color(0xFFE2E8F0);
    final textPrimary =
        widget.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSecondary =
        widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final textHint =
        widget.isDark ? const Color(0xFF4A5568) : const Color(0xFF94A3B8);
    const primaryAction = Color(0xFF2563EB);

    final hoverBgColor = primaryAction.withValues(alpha: 0.03);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: _isHovered ? hoverBgColor : bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered ? primaryAction : borderColor,
                width: widget.isDark && !_isHovered ? 0.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(widget.icon, size: 22, color: primaryAction),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: textHint,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

