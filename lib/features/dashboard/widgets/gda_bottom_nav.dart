import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';

/// GDA Vault AI — Floating Bubble Notch Bottom Navigation
/// Active item rises above bar inside a themed circle.
/// Notch slides smoothly with bezier curves on tab switch.
class GdaBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GdaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<GdaBottomNav> createState() => _GdaBottomNavState();
}

class _GdaBottomNavState extends State<GdaBottomNav>
    with TickerProviderStateMixin {
  // Notch slide
  late AnimationController _slideCtrl;
  late Animation<double> _slideAnim;
  double _fromX = -1;
  double _toX = -1;

  // Bubble pop
  late AnimationController _popCtrl;
  late Animation<double> _popAnim;

  // Bubble lift
  late AnimationController _liftCtrl;
  late Animation<double> _liftAnim;

  // Glow
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  // Icon Rotation
  late AnimationController _rotateCtrl;
  late Animation<double> _rotateAnim;

  // Per-tab tap scales
  late List<AnimationController> _tapCtrls;
  late List<Animation<double>> _tapScales;

  static const double _barHeight = 68.0;
  static const double _bubbleRadius = 26.0;
  static const double _bubbleLift = 22.0;
  static const double _horizontalInset = 20.0;
  static const int _count = 5;

  static const List<_TabItem> _tabs = [
    _TabItem(icon: Icons.home_rounded, label: 'Home'),
    _TabItem(icon: Icons.folder_copy_rounded, label: 'Categories'),
    _TabItem(icon: Icons.add_rounded, label: 'Add'),
    _TabItem(icon: Icons.auto_awesome_rounded, label: 'AI Chat'),
    _TabItem(icon: Icons.tune_rounded, label: 'Settings'),
  ];

  double _tabWidth = 0;

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slideAnim = _slideCtrl.drive(Tween(begin: 0.0, end: 0.0));

    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _popAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.90), weight: 24),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.04), weight: 46),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _popCtrl, curve: Curves.easeOutCubic));

    _liftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _liftAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 35),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 65),
    ]).animate(CurvedAnimation(parent: _liftCtrl, curve: Curves.easeOutCubic));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _rotateAnim = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _rotateCtrl, curve: Curves.elasticOut));

    _tapCtrls = List.generate(
      _count,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 180),
      ),
    );
    _tapScales = _tapCtrls.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.80), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 0.80, end: 1.0), weight: 60),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
    }).toList();
  }

  @override
  void didUpdateWidget(GdaBottomNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex && _tabWidth > 0) {
      _animateSwitch(old.currentIndex, widget.currentIndex);
    }
  }

  void _animateSwitch(int from, int to) {
    _fromX = _centerX(from);
    _toX = _centerX(to);

    _slideAnim = Tween<double>(begin: _fromX, end: _toX).animate(
      CurvedAnimation(
        parent: _slideCtrl,
        curve: Curves.easeInOutCubicEmphasized,
      ),
    );
    _slideCtrl.forward(from: 0);
    _popCtrl.forward(from: 0);
    _liftCtrl.forward(from: 0);
    _rotateCtrl.forward(from: 0);
  }

  double _centerX(int index) =>
      _horizontalInset + _tabWidth * index + _tabWidth / 2;

  void _handleTap(int index) {
    if (index == widget.currentIndex) return;
    HapticFeedback.lightImpact();
    _tapCtrls[index].forward(from: 0);
    widget.onTap(index);
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _popCtrl.dispose();
    _liftCtrl.dispose();
    _glowCtrl.dispose();
    _rotateCtrl.dispose();
    for (final c in _tapCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF141414) : Colors.white;
    final borderTop = isDark ? const Color(0xFF272727) : const Color(0xFFE4E7EC);
    final activeColor = isDark ? const Color(0xFF63B3ED) : const Color(0xFF2C5282);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final effectiveWidth = constraints.maxWidth - _horizontalInset * 2;
        _tabWidth = effectiveWidth / _count;

        if (_fromX < 0) {
          _fromX = _centerX(widget.currentIndex);
          _toX = _fromX;
          _slideAnim = AlwaysStoppedAnimation(_fromX);
        }

        return AnimatedBuilder(
          animation: Listenable.merge([
            _slideAnim,
            _popAnim,
            _liftAnim,
            _glowAnim,
            _rotateAnim,
            ..._tapScales,
          ]),
          builder: (context, child) {
            final notchX = _slideAnim.value.clamp(
              _horizontalInset + _bubbleRadius,
              constraints.maxWidth - _horizontalInset - _bubbleRadius,
            );
            final glow = _glowAnim.value;

            return SizedBox(
              height: _barHeight + _bubbleLift + 10,
              width: constraints.maxWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, _barHeight),
                      painter: _NotchedBarPainter(
                        notchX: notchX,
                        notchRadius: _bubbleRadius + 6,
                        barHeight: _barHeight,
                        barColor: navBg,
                        borderColor: borderTop,
                      ),
                    ),
                  ),

                  // Subtle gradient overlay for the bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: _barHeight,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              activeColor.withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: _barHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _horizontalInset,
                      ),
                      child: Row(
                        children: List.generate(
                          _count,
                          (i) => _buildSlot(i, notchX, isDark),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    left: notchX - _bubbleRadius,
                    bottom: _barHeight - _bubbleRadius + _bubbleLift / 2 - 5,
                    child: Transform.translate(
                      offset: Offset(0, _liftAnim.value),
                      child: Transform.scale(
                        scale: _popAnim.value,
                        child: _buildBubble(glow, isDark, activeColor),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSlot(int index, double notchX, bool isDark) {
    final isActive = index == widget.currentIndex;
    final tab = _tabs[index];
    
    final activeColor = isDark ? const Color(0xFF63B3ED) : const Color(0xFF2C5282);
    final inactiveColor = isDark ? const Color(0xFF8899B0) : const Color(0xFF64748B);

    return Expanded(
      child: _HoverTabItem(
        isActive: isActive,
        tab: tab,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        tapScale: _tapScales[index],
        onTap: () => _handleTap(index),
      ),
    );
  }

  Widget _buildBubble(double glow, bool isDark, Color activeColor) {
    final tab = _tabs[widget.currentIndex];
    
    final gradientColors = isDark 
        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
        : [const Color(0xFF2C5282), const Color(0xFF1A365D)];

    final iconColor = isDark ? activeColor : Colors.white;

    return Container(
      width: _bubbleRadius * 2,
      height: _bubbleRadius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: activeColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: activeColor.withValues(alpha: 0.1 + glow * 0.15),
            blurRadius: 6 + glow * 4,
            spreadRadius: glow * 1.5,
          ),
        ],
      ),
      child: Transform.rotate(
        angle: _rotateAnim.value,
        child: Icon(tab.icon, size: 24, color: iconColor),
      ),
    );
  }
}

class _HoverTabItem extends StatefulWidget {
  final bool isActive;
  final _TabItem tab;
  final Color activeColor;
  final Color inactiveColor;
  final Animation<double> tapScale;
  final VoidCallback onTap;

  const _HoverTabItem({
    required this.isActive,
    required this.tab,
    required this.activeColor,
    required this.inactiveColor,
    required this.tapScale,
    required this.onTap,
  });

  @override
  State<_HoverTabItem> createState() => _HoverTabItemState();
}

class _HoverTabItemState extends State<_HoverTabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = widget.activeColor.withValues(alpha: 0.8);
    final color = widget.isActive
        ? widget.activeColor
        : (_isHovered ? hoverColor : widget.inactiveColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isActive) ...[
              const SizedBox(height: 38), // Space for the bubble
              const SizedBox(height: 2),
              Text(
                widget.tab.label.toUpperCase(),
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.6,
                ),
              ),
            ] else ...[
              Transform.scale(
                scale: _isHovered ? 1.05 : widget.tapScale.value,
                child: Icon(
                  widget.tab.icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.tab.label,
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotchedBarPainter extends CustomPainter {
  final double notchX;
  final double notchRadius;
  final double barHeight;
  final Color barColor;
  final Color borderColor;

  const _NotchedBarPainter({
    required this.notchX,
    required this.notchRadius,
    required this.barHeight,
    required this.barColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.05), 8, false);

    canvas.drawPath(
      path,
      Paint()
        ..color = barColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  Path _path(Size size) {
    const double cr = 24.0; // Corner radius
    final double nr = notchRadius;
    final double lft = notchX - nr;
    final double rgt = notchX + nr;

    // Smoothness factor for the notch shoulders
    const double s = 14.0;

    final path = Path();

    // Start from top-left
    path.moveTo(0, cr);
    path.quadraticBezierTo(0, 0, cr, 0);

    // Line to left shoulder of the notch
    path.lineTo((lft - s).clamp(cr, size.width), 0);

    // Smoother cubic notch transition
    path.cubicTo(lft + s * 0.2, 0, lft + s * 0.1, nr * 1.05, notchX, nr * 1.05);

    path.cubicTo(
      rgt - s * 0.1,
      nr * 1.05,
      rgt - s * 0.2,
      0,
      (rgt + s).clamp(0.0, size.width - cr),
      0,
    );

    // Line to top-right
    path.lineTo(size.width - cr, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cr);

    // Complete the box
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(_NotchedBarPainter old) =>
      old.notchX != notchX || old.barColor != barColor;
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}
