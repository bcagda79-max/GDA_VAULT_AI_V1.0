import 'package:flutter/material.dart';
import 'auth_colors.dart';
import 'auth_text_styles.dart';

/// 3-segment password strength indicator.
///
/// - Weak (1 segment, red #DC2626): < 6 chars
/// - Medium (2 segments, amber #F59E0B): 6–7 chars
/// - Strong (3 segments, green #16A34A): 8+ chars with mixed case/number/symbol
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  _StrengthLevel get _strength {
    if (password.isEmpty) return _StrengthLevel.none;
    if (password.length < 6) return _StrengthLevel.weak;

    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score >= 3) return _StrengthLevel.strong;
    if (score >= 1) return _StrengthLevel.medium;
    return _StrengthLevel.medium;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _strength;
    if (strength == _StrengthLevel.none) return const SizedBox.shrink();

    final activeCount = switch (strength) {
      _StrengthLevel.weak => 1,
      _StrengthLevel.medium => 2,
      _StrengthLevel.strong => 3,
      _StrengthLevel.none => 0,
    };

    final color = switch (strength) {
      _StrengthLevel.weak => AuthColors.strengthWeak,
      _StrengthLevel.medium => AuthColors.strengthMedium,
      _StrengthLevel.strong => AuthColors.strengthStrong,
      _StrengthLevel.none => Colors.transparent,
    };

    final label = switch (strength) {
      _StrengthLevel.weak => 'Weak',
      _StrengthLevel.medium => 'Medium',
      _StrengthLevel.strong => 'Strong',
      _StrengthLevel.none => '',
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (index) {
              final isActive = index < activeCount;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? color
                        : (Theme.of(context).brightness == Brightness.dark
                            ? AuthColors.darkBorder
                            : AuthColors.lightBorder),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AuthTextStyles.error(color: color),
          ),
        ],
      ),
    );
  }
}

enum _StrengthLevel { none, weak, medium, strong }
