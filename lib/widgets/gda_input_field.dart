// lib/widgets/gda_input_field.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class GdaInputField extends StatefulWidget {
  final String hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool obscure;
  final bool suffixToggle;
  final String? errorText;
  final TextEditingController? controller;

  const GdaInputField({
    super.key,
    required this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.obscure = false,
    this.suffixToggle = false,
    this.errorText,
    this.controller,
  });

  @override
  State<GdaInputField> createState() => _GdaInputFieldState();
}

class _GdaInputFieldState extends State<GdaInputField> {
  bool _hasFocus = false;
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgSurface = isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight = isDark ? AppTokens.darkBorderLight : AppTokens.lightBorderLight;
    final brandPrimary = isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;
    final statusError = isDark ? AppTokens.darkStatusError : AppTokens.lightStatusError;
    final shadowXs = isDark ? AppTokens.darkShadowXs : AppTokens.lightShadowXs;
    final textTertiary = isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary;
    final textPrimary = isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary;

    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // Focus / Error border & shadow logic
    Color borderColor = borderLight;
    double borderWidth = 1.0;
    List<BoxShadow>? currentShadow = shadowXs;

    if (hasError) {
      borderColor = statusError;
      borderWidth = 1.5;
      currentShadow = [
        BoxShadow(
          color: const Color(0xFFF04438).withValues(alpha: 0.10),
          blurRadius: 0,
          spreadRadius: 3,
        ),
      ];
    } else if (_hasFocus) {
      borderColor = brandPrimary;
      borderWidth = 1.5;
      currentShadow = [
        BoxShadow(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          blurRadius: 0,
          spreadRadius: 3,
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: currentShadow,
          ),
          child: FocusScope(
            child: Focus(
              onFocusChange: (focused) => setState(() => _hasFocus = focused),
              child: TextField(
                controller: widget.controller,
                keyboardType: widget.keyboardType,
                obscureText: _isObscured,
                style: AppTextStyles.bodyMd.copyWith(color: textPrimary),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: AppTextStyles.bodyMd.copyWith(color: textTertiary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(widget.prefixIcon, size: 18, color: textTertiary)
                      : null,
                  suffixIcon: widget.suffixToggle
                      ? IconButton(
                          icon: Icon(
                            _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 18,
                            color: textTertiary,
                          ),
                          onPressed: () => setState(() => _isObscured = !_isObscured),
                          splashRadius: 20,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 12, color: statusError),
              const SizedBox(width: 4),
              Text(
                widget.errorText!,
                style: TextStyle(
                  fontSize: 11,
                  color: statusError,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
