// lib/widgets/gda_primary_button.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class GdaPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const GdaPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<GdaPrimaryButton> createState() => _GdaPrimaryButtonState();
}

class _GdaPrimaryButtonState extends State<GdaPrimaryButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.isLoading) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isLoading) return;
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    if (widget.isLoading) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final brandPrimary = isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;
    final brandHover = isDark ? AppTokens.darkBrandHover : AppTokens.lightBrandHover;
    final shadowSm = isDark ? AppTokens.darkShadowSm : AppTokens.lightShadowSm;

    final double scale = _isPressed ? 0.975 : 1.0;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isLoading ? brandHover : brandPrimary,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            boxShadow: _isPressed ? [] : shadowSm, // slight push effect
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  )
                : Text(
                    widget.label,
                    style: AppTextStyles.labelLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
