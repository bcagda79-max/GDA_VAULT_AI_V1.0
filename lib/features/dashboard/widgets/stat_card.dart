import 'package:flutter/material.dart';

/// A reusable statistics card for the dashboard (Mobile & Desktop).
class StatCard extends StatelessWidget {
  final String label;
  final String number;
  final IconData icon;
  final bool isDark;
  final bool isMobile;

  const StatCard({
    super.key,
    required this.label,
    required this.number,
    required this.icon,
    required this.isDark,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF272727) : const Color(0xFFE2E8F0);
    final textPrimary =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final textHint = isDark ? const Color(0xFF4A5568) : const Color(0xFF94A3B8);
    const accentColor = Color(0xFF2563EB); // Consistent accent line

    final padding =
        isMobile ? const EdgeInsets.symmetric(horizontal: 12, vertical: 14) : const EdgeInsets.all(20);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isDark ? 0.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMobile)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 18, color: textHint),
              ],
            )
          else
            Align(
              alignment: Alignment.topRight,
              child: Icon(icon, size: 16, color: textHint),
            ),
          
          if (!isMobile) const SizedBox(height: 8),
          
          Text(
            number,
            style: TextStyle(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              height: 1.1,
            ),
          ),
          
          if (isMobile) const SizedBox(height: 2),
          if (isMobile)
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
          const SizedBox(height: 12),
          // Bottom accent line
          Container(
            height: 2,
            width: isMobile ? 28 : 40,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}


