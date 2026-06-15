import 'package:flutter/material.dart';
import 'auth_colors.dart';
import 'auth_text_styles.dart';
import 'gda_feature_item.dart';

/// Shared left branding panel for desktop split layouts.
///
/// Used identically by both Login and Signup screens.
/// Dark navy #0D1B2E background, grid painter, logo, features, copyright.
class AuthLeftPanel extends StatelessWidget {
  const AuthLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AuthColors.leftPanelBg,
      child: Stack(
        children: [
          // Grid background
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                color: Colors.white.withValues(alpha: 0.02),
              ),
            ),
          ),

          // Ambient glow
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AuthColors.featureIconColor.withValues(alpha: 0.06),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Content — vertically centered
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo — clean, no border/ring
                  Image.asset(
                    'assets/images/gda_logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.business, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'GDA Vault AI',
                    style: AuthTextStyles.displayTitle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'GALIYAT DEVELOPMENT AUTHORITY',
                    style: AuthTextStyles.subtitle(
                      color: const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.only(top: 28),
                    child: Container(
                      width: 160,
                      height: 1,
                      color: AuthColors.featureIconBg,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Feature list — centered
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const Column(
                      children: [
                        GdaFeatureItem(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Interactive File Queries',
                          subtitle: 'Ask questions, get instant cited answers',
                        ),
                        GdaFeatureItem(
                          icon: Icons.psychology_outlined,
                          title: 'Contextual Document Chat',
                          subtitle:
                              'Converse with folders and scanned PDFs',
                        ),
                        GdaFeatureItem(
                          icon: Icons.cloud_off_rounded,
                          title: 'Sovereign Vault Caching',
                          subtitle: 'Access records offline, securely',
                        ),
                        GdaFeatureItem(
                          icon: Icons.shield_outlined,
                          title: 'Enterprise Security',
                          subtitle:
                              'Encrypted systems, operational compliance',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Copyright
                  Text(
                    '© 2026 Galiyat Development Authority',
                    style: AuthTextStyles.copyright(
                      color: const Color(0xFF475569),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const double step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
