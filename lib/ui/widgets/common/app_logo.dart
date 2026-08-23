import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Crisp native vector logo for Budasswords matching the exact shield-padlock artwork.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showContainer;

  const AppLogo({
    super.key,
    this.size = 48,
    this.showContainer = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget icon = CustomPaint(
      size: Size(size, size),
      painter: _ShieldPadlockPainter(),
    );

    if (!showContainer) return icon;

    return Container(
      width: size * 1.45,
      height: size * 1.45,
      decoration: BoxDecoration(
        color: AppColors.bg2,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: icon,
        ),
      ),
    );
  }
}

class _ShieldPadlockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 1. Shackle (Top Arch) ──
    final shackleLeftPaint = Paint()
      ..color = const Color(0xFFF5A623)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.088
      ..strokeCap = StrokeCap.butt;

    final shackleRightPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.088
      ..strokeCap = StrokeCap.butt;

    final shackleRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.38),
      width: w * 0.38,
      height: h * 0.46,
    );

    // Draw left half of arch
    canvas.drawArc(
      shackleRect,
      math.pi,
      math.pi * 0.5,
      false,
      shackleLeftPaint,
    );
    // Draw right half of arch
    canvas.drawArc(
      shackleRect,
      math.pi * 1.5,
      math.pi * 0.5,
      false,
      shackleRightPaint,
    );

    // ── 2. Outer Shield Outline ──
    final outerStrokePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFBBF24),
          Color(0xFFEA580C),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.square;

    final outerPath = Path();
    // Start at top peak
    outerPath.moveTo(w * 0.50, h * 0.34);
    // Top-left shoulder
    outerPath.lineTo(w * 0.22, h * 0.40);
    // Left vertical side
    outerPath.lineTo(w * 0.22, h * 0.60);
    // Left curve down to bottom tip
    outerPath.quadraticBezierTo(w * 0.23, h * 0.77, w * 0.50, h * 0.90);
    // Right curve up from bottom tip
    outerPath.quadraticBezierTo(w * 0.77, h * 0.77, w * 0.77, h * 0.60);
    // Right vertical side (with stylized notch / monogram cut)
    outerPath.lineTo(w * 0.77, h * 0.54);
    outerPath.lineTo(w * 0.65, h * 0.54);
    outerPath.moveTo(w * 0.77, h * 0.48);
    outerPath.lineTo(w * 0.77, h * 0.40);
    // Top-right shoulder back to peak
    outerPath.lineTo(w * 0.50, h * 0.34);

    canvas.drawPath(outerPath, outerStrokePaint);

    // ── 3. Inner Shield (Filled with 2-Tone Split) ──
    final innerPath = Path();
    innerPath.moveTo(w * 0.50, h * 0.42);
    innerPath.lineTo(w * 0.30, h * 0.46);
    innerPath.lineTo(w * 0.30, h * 0.60);
    innerPath.quadraticBezierTo(w * 0.31, h * 0.74, w * 0.50, h * 0.84);
    innerPath.quadraticBezierTo(w * 0.69, h * 0.74, w * 0.69, h * 0.60);
    innerPath.lineTo(w * 0.69, h * 0.46);
    innerPath.close();

    // Left Half: Bright Gold
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * 0.50, h));
    final leftFillPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, leftFillPaint);
    canvas.restore();

    // Right Half: Rich Amber/Terracotta
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(w * 0.50, 0, w * 0.50, h));
    final rightFillPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, rightFillPaint);
    canvas.restore();

    // ── 4. Keyhole (Circle + Trapezoid Keyway in Dark Graphite) ──
    final keyholePaint = Paint()
      ..color = const Color(0xFF16181D)
      ..style = PaintingStyle.fill;

    // Top Circle
    canvas.drawCircle(Offset(w * 0.50, h * 0.58), w * 0.075, keyholePaint);

    // Lower Trapezoid
    final keywayPath = Path()
      ..moveTo(w * 0.46, h * 0.60)
      ..lineTo(w * 0.54, h * 0.60)
      ..lineTo(w * 0.56, h * 0.74)
      ..lineTo(w * 0.44, h * 0.74)
      ..close();

    canvas.drawPath(keywayPath, keyholePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
