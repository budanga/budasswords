import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Crisp native vector logo for Budasswords, identical to the launcher icon.
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

/// Paints the same artwork as the launcher icon (assets/logo.png).
/// Coordinates are in the icon's 1024px design space, cropped to the glyph.
class _ShieldPadlockPainter extends CustomPainter {
  static const _origin = Offset(192, 203);
  static const _extent = 640.0;
  static const _shieldShade = Color(0xFF9E4A2E);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _extent, size.height / _extent);
    canvas.translate(-_origin.dx, -_origin.dy);

    // ── 1. Shackle ──
    final shackle = Path()
      ..moveTo(392, 455)
      ..lineTo(392, 360)
      ..arcTo(Rect.fromCircle(center: const Offset(512, 360), radius: 120),
          math.pi, math.pi, false)
      ..lineTo(632, 455);
    canvas.drawPath(
      shackle,
      Paint()
        ..color = AppColors.textPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 58,
    );

    // ── 2. Shield, two-tone terracotta ──
    final leftHalf = Path()
      ..moveTo(512, 400)
      ..lineTo(296, 450)
      ..lineTo(296, 600)
      ..quadraticBezierTo(300, 736, 512, 836)
      ..close();
    final rightHalf = Path()
      ..moveTo(512, 400)
      ..lineTo(728, 450)
      ..lineTo(728, 600)
      ..quadraticBezierTo(724, 736, 512, 836)
      ..close();
    canvas.drawPath(leftHalf, Paint()..color = AppColors.accent);
    canvas.drawPath(rightHalf, Paint()..color = _shieldShade);

    // ── 3. Inner rule ──
    final inner = Path()
      ..moveTo(512, 452)
      ..lineTo(344, 490)
      ..lineTo(344, 598)
      ..quadraticBezierTo(348, 702, 512, 782)
      ..quadraticBezierTo(676, 702, 680, 598)
      ..lineTo(680, 490)
      ..close();
    canvas.drawPath(
      inner,
      Paint()
        ..color = AppColors.bg0.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    // ── 4. Keyhole ──
    final keyhole = Paint()..color = AppColors.bg0;
    canvas.drawCircle(const Offset(512, 582), 40, keyhole);
    canvas.drawPath(
      Path()
        ..moveTo(492, 600)
        ..lineTo(472, 690)
        ..lineTo(552, 690)
        ..lineTo(532, 600)
        ..close(),
      keyhole,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
