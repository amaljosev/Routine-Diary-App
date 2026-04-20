import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.onCalendarTap,
    required this.onSettingsTap,
    required this.onFabTap,
  });

  final VoidCallback onCalendarTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onFabTap;

  static const double _fabSize = 70;
  static const double _barHeight = 64;
  static const double _totalHeight = 110;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color barColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50;
    final Color inactiveColor = isDark
        ? Colors.white38
        : Theme.of(context).primaryColor.withValues(alpha: 0.5);

    return SafeArea(
      child: SizedBox(
        height: _totalHeight,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            /// NAV BAR
            Positioned(
              bottom: 12,
              left: 20,
              right: 20,
              child: CustomPaint(
                painter: _NotchedPillPainter(
                  color: barColor,
                  fabRadius: _fabSize / 2,
                  isDark: isDark,
                ),
                child: SizedBox(
                  height: _barHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavItem(
                          icon: Icons.calendar_month,
                          color: inactiveColor,
                          onTap: onCalendarTap,
                        ),
                      ),
                      const SizedBox(width: _fabSize + 16),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.settings,
                          color: inactiveColor,
                          onTap: onSettingsTap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// FAB BUTTON
            Positioned(
              bottom: 30,
              child: GestureDetector(
                onTap: onFabTap,
                child: Container(
                  width: _fabSize,
                  height: _fabSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Single nav item ──────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        height: double.infinity,
        child: Center(child: Icon(icon, color: color, size: 24)),
      ),
    );
  }
}

// ─── CustomPainter: floating pill with smooth concave notch ───────────────────

class _NotchedPillPainter extends CustomPainter {
  const _NotchedPillPainter({
    required this.color,
    required this.fabRadius,
    required this.isDark,
  });

  final Color color;
  final double fabRadius;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final double h = size.height;
    final double w = size.width;
    final double cx = w / 2;

    final double notchR = fabRadius + 10;
    const double notchDepth = 14.0;
    const double notchSmoothWidth = 18.0;

    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(h / 2, 0)
      ..lineTo(cx - notchR - notchSmoothWidth, 0)
      ..cubicTo(
        cx - notchR - notchSmoothWidth / 2, 0,
        cx - notchR, 0,
        cx - notchR, notchDepth,
      )
      ..arcToPoint(
        Offset(cx + notchR, notchDepth),
        radius: Radius.circular(notchR),
        clockwise: false,
      )
      ..cubicTo(
        cx + notchR, 0,
        cx + notchR + notchSmoothWidth / 2, 0,
        cx + notchR + notchSmoothWidth, 0,
      )
      ..lineTo(w - h / 2, 0)
      ..arcToPoint(
        Offset(w - h / 2, h),
        radius: Radius.circular(h / 2),
        clockwise: true,
      )
      ..lineTo(h / 2, h)
      ..arcToPoint(
        Offset(h / 2, 0),
        radius: Radius.circular(h / 2),
        clockwise: true,
      )
      ..close();

    canvas.drawShadow(
      path,
      isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.12),
      12,
      false,
    );

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _NotchedPillPainter old) =>
      old.color != color || old.isDark != isDark;
}