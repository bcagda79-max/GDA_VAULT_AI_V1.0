import 'package:flutter/material.dart';
import 'auth_colors.dart';
import 'auth_text_styles.dart';

/// Reusable primary action button for auth screens.
///
/// Features:
/// - 52px height, 10px border-radius
/// - Scale-down press animation (0.97)
/// - Hover effect: color changes to darker shade
/// - AnimatedSize loading state (shrinks to 52px width, shows spinner)
/// - Consistent #2563EB on both light and dark
class GdaButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GdaButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<GdaButton> createState() => _GdaButtonState();
}

class _GdaButtonState extends State<GdaButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bool isDisabled = widget.onPressed == null && !widget.isLoading;

    final Color bgColor;
    if (isDisabled) {
      bgColor = cs.primary.withValues(alpha: 0.5);
    } else if (_isPressed) {
      bgColor = AuthColors.actionBlueHover;
    } else if (_isHovered) {
      bgColor = AuthColors.actionBlueHover;
    } else {
      bgColor = cs.primary;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isDisabled
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown:
            widget.isLoading ? null : (_) => setState(() => _isPressed = true),
        onTapUp:
            widget.isLoading ? null : (_) => setState(() => _isPressed = false),
        onTapCancel:
            widget.isLoading ? null : () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: 52,
            width: widget.isLoading ? 52 : double.infinity,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(
                      alpha: _isHovered || _isPressed ? 0.35 : 0.2),
                  blurRadius: _isHovered ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                borderRadius: BorderRadius.circular(10),
                splashColor: Colors.white.withValues(alpha: 0.15),
                highlightColor: Colors.white.withValues(alpha: 0.05),
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.text,
                          style: AuthTextStyles.button(color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
