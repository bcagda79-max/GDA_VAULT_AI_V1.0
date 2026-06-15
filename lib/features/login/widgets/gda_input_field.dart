import 'package:flutter/material.dart';
import 'auth_colors.dart';
import 'auth_text_styles.dart';

/// Reusable themed input field for auth screens.
///
/// Features:
/// - Uppercase label above the field
/// - 52px height, 10px border-radius
/// - Animated border color on focus (150ms)
/// - Focus glow shadow
/// - Error display below field (red icon + text)
class GdaInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const GdaInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  State<GdaInputField> createState() => _GdaInputFieldState();
}

class _GdaInputFieldState extends State<GdaInputField> {
  bool _hasFocus = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    final focused = widget.focusNode.hasFocus;
    if (focused != _hasFocus) {
      setState(() => _hasFocus = focused);
    }
    // Validate on blur
    if (!focused && widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(widget.controller.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = _errorText != null
        ? cs.error
        : _hasFocus
            ? cs.primary
            : cs.outline;

    final borderWidth = _hasFocus || _errorText != null ? 2.0 : 1.0;

    final fillColor = _hasFocus
        ? (isDark ? AuthColors.darkSurface : Colors.white)
        : cs.surfaceContainerHighest;

    final textSecondary = isDark
        ? AuthColors.darkTextSecondary
        : AuthColors.lightTextSecondary;

    final textHint = isDark
        ? AuthColors.darkTextHint
        : AuthColors.lightTextHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Uppercase label
        Text(
          widget.label.toUpperCase(),
          style: AuthTextStyles.label(color: textSecondary),
        ),
        const SizedBox(height: 8),

        // Input container with animated border + shadow
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hasFocus
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            style: AuthTextStyles.input(color: cs.onSurface),
            validator: (value) {
              final error = widget.validator?.call(value);
              // We handle display ourselves, but still return error
              // so Form.validate() works correctly.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _errorText = error);
                }
              });
              return error;
            },
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AuthTextStyles.input(color: textHint),
              prefixIcon: Icon(
                widget.prefixIcon,
                size: 18,
                color: textHint,
              ),
              suffixIcon: widget.suffixIcon,
              filled: true,
              fillColor: fillColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              // Remove default error text since we show it ourselves below
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor, width: borderWidth),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.outline, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.error, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.error, width: 2),
              ),
            ),
          ),
        ),

        // Error text below field
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topLeft,
          child: _errorText != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 14, color: cs.error),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: AuthTextStyles.error(color: cs.error),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
