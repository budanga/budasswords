import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'motion_kit.dart';

/// A small pixel cloud for the sync badge. While [syncing], a dithered wave
/// of [color] sweeps across it; otherwise it is filled solid with [color].
class DitherCloud extends StatefulWidget {
  const DitherCloud({super.key, required this.syncing, required this.color});

  final bool syncing;
  final Color color;

  static const cols = 14, rows = 10, cell = 1.6;

  /// Cells inside the cloud silhouette (three bumps over a flat base).
  static final List<(int, int)> mask = [
    for (var y = 0; y < rows; y++)
      for (var x = 0; x < cols; x++)
        if (_inCloud(x + 0.5, y + 0.5)) (x, y),
  ];

  static bool _inCloud(double px, double py) {
    bool circle(double cx, double cy, double r) => math.pow(px - cx, 2) + math.pow(py - cy, 2) <= r * r;
    return circle(4.4, 6, 2.9) ||
        circle(7.6, 4.4, 3.5) ||
        circle(10.6, 6.2, 2.6) ||
        (px > 2 && px < 12.5 && py > 6 && py < 8.9);
  }

  @override
  State<DitherCloud> createState() => _DitherCloudState();
}

class _DitherCloudState extends State<DitherCloud>
    with TickerProviderStateMixin, MotionClock {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(DitherCloud old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() => widget.syncing && Motion.enabled(context) ? startClock() : stopClock();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: DitherCloud.cols * DitherCloud.cell,
        height: DitherCloud.rows * DitherCloud.cell,
        child: CustomPaint(
          painter: _CloudPainter(time: time, syncing: widget.syncing, color: widget.color),
        ),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  _CloudPainter({required this.time, required this.syncing, required this.color})
      : super(repaint: time);

  final ValueNotifier<double> time;
  final bool syncing;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const c = DitherCloud.cell;
    final on = Paint()..color = color;
    final off = Paint()..color = AppColors.border;
    final t = time.value;
    for (final (x, y) in DitherCloud.mask) {
      final lit = !syncing || 0.5 + 0.5 * math.sin(t * 5 - x * 0.7) > Bayer.b4.at(x, y);
      canvas.drawRect(Rect.fromLTWH(x * c, y * c, c, c), lit ? on : off);
    }
  }

  @override
  bool shouldRepaint(_CloudPainter old) => old.syncing != syncing || old.color != color;
}
