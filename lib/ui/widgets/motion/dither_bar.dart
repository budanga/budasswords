import 'package:flutter/material.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'motion_kit.dart';

/// A progress bar drawn as ordered-dither pixels: the fill edge dissolves in
/// a Bayer 4×4 pattern instead of being a hard line.
class DitherBar extends StatelessWidget {
  const DitherBar({
    super.key,
    required this.value,
    this.color = AppColors.accent,
    this.trackColor = AppColors.bg3,
    this.height = 8,
    this.pixel = 2,
    this.softness = 16,
  });

  /// Filled fraction, 0–1.
  final double value;
  final Color color;
  final Color trackColor;
  final double height;
  final double pixel;

  /// Width of the dissolving edge, in pixels-cells.
  final double softness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: DitherBarPainter(
          value: value,
          color: color,
          trackColor: trackColor,
          pixel: pixel,
          softness: softness,
        ),
      ),
    );
  }
}

class DitherBarPainter extends CustomPainter {
  DitherBarPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.pixel,
    required this.softness,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double pixel;
  final double softness;

  /// Whether the cell at [cx], [cy] is lit for [value] across [cols] cells.
  static bool lit(int cx, int cy, int cols, double value, double softness) {
    final edge = value.clamp(0.0, 1.0) * (cols + softness) - softness / 2;
    final v = ((edge - cx) / softness + 0.5).clamp(0.0, 1.0);
    return v > Bayer.b4.at(cx, cy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = trackColor);
    final cols = (size.width / pixel).floor(), rows = (size.height / pixel).floor();
    final paint = Paint()..color = color;
    for (var cy = 0; cy < rows; cy++) {
      for (var cx = 0; cx < cols; cx++) {
        if (lit(cx, cy, cols, value, softness)) {
          canvas.drawRect(Rect.fromLTWH(cx * pixel, cy * pixel, pixel, pixel), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(DitherBarPainter old) =>
      old.value != value || old.color != color || old.trackColor != trackColor;
}
