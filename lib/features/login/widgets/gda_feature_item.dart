import 'package:flutter/material.dart';
import 'auth_colors.dart';
import 'auth_text_styles.dart';

/// Feature row widget for the left branding panel.
///
/// 40x40 icon container with 10px radius, #1E3A5F bg, #3B82F6 icon.
/// Title 14sp white w500 + subtitle 12sp #64748B.
class GdaFeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const GdaFeatureItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AuthColors.featureIconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AuthColors.featureIconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),

          // Text column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AuthTextStyles.featureTitle(color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AuthTextStyles.featureSubtitle(
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
