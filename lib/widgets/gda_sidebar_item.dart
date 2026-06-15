import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

class GdaSidebarItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const GdaSidebarItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<GdaSidebarItem> createState() => _GdaSidebarItemState();
}

class _GdaSidebarItemState extends State<GdaSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Enterprise Professional Palette
    final defaultColor = isDark ? const Color(0xFF8899B0) : const Color(0xFF64748B);
    final hoverColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final activeColor = Colors.white;
    
    final accentColor = isDark ? AppTokens.darkBrandPrimary : AppTokens.lightBrandPrimary;
    
    // Backgrounds
    final activeBgColor = accentColor.withValues(alpha: 0.15);
    final hoverBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04);

    final currentTextColor = widget.selected 
        ? activeColor 
        : (_isHovered ? hoverColor : defaultColor);
        
    final currentIconColor = widget.selected 
        ? accentColor 
        : (_isHovered ? hoverColor : defaultColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 46,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: widget.selected 
                ? activeBgColor 
                : (_isHovered ? hoverBgColor : Colors.transparent),
            border: Border.all(
              color: widget.selected 
                  ? accentColor.withValues(alpha: 0.3) 
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Active Glowing Indicator Line
              if (widget.selected)
                Positioned(
                  left: 0,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              
              Row(
                children: [
                  const SizedBox(width: 14),
                  AnimatedTheme(
                    data: Theme.of(context).copyWith(
                      iconTheme: IconThemeData(color: currentIconColor),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 22,
                      color: currentIconColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      style: AppTextStyles.labelLg.copyWith(
                        fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                        color: currentTextColor,
                        letterSpacing: 0.3,
                      ),
                      child: Text(widget.label),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
