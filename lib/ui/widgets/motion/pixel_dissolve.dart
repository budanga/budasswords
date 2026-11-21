import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'motion_kit.dart';

/// Opening and locking the vault: terracotta pixels appear at random until
/// they cover the screen, the screen underneath changes, and the pixels go
/// out at random to reveal the new one.
///
/// Wraps the whole app. When [open] flips, it snapshots what was on screen
/// a moment before, covers that snapshot, then uncovers the new screen. The
/// snapshot is released as soon as it is fully covered.
class PixelDissolve extends StatefulWidget {
  const PixelDissolve({super.key, required this.open, required this.child});

  /// Flip it to play the transition (vault unlocked ↔ locked).
  final bool open;
  final Widget child;

  static const cell = 6.0;
  static const duration = Duration(milliseconds: 1500);

  /// Close terracotta tones, so the cover reads as one colour, not a checkerboard.
  static const tones = [Color(0xFFBA5A3A), Color(0xFFB45537), Color(0xFFBF5F3F)];

  /// A pixel that just appeared or is about to go out.
  static const fresh = Color(0xFFC4674A);

  /// Pixel progress for [t] (0–1 of the whole transition) and whether pixels
  /// are appearing (true) or going out (false). Holds fully covered in between.
  static (double, bool) phase(double t) {
    double ease(double x) => x < .5 ? 2 * x * x : 1 - math.pow(-2 * x + 2, 2) / 2;
    if (t < 0.47) return (ease(t / 0.47), true);
    if (t < 0.53) return (1, true);
    return (ease(((t - 0.53) / 0.47).clamp(0.0, 1.0)), false);
  }

  @override
  State<PixelDissolve> createState() => _PixelDissolveState();
}

class _PixelDissolveState extends State<PixelDissolve> with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  final _rng = math.Random();
  late final AnimationController _c = AnimationController(vsync: this, duration: PixelDissolve.duration)
    ..addListener(_releaseSnapshotOnceCovered)
    ..addStatusListener((_) {
      if (mounted) setState(() {});
    });
  ui.Image? _snapshot;
  Float32List _order = Float32List(0);
  Uint8List _tone = Uint8List(0);
  int _cols = 0;

  @override
  void didUpdateWidget(PixelDissolve old) {
    super.didUpdateWidget(old);
    if (old.open != widget.open) _play();
  }

  void _play() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    // Locking in the background must not replay the vault on resume.
    final foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    if (!foreground || !Motion.enabled(context)) return;

    _takeSnapshot();
    _shuffle(MediaQuery.sizeOf(context));
    _c.forward(from: 0);
  }

  void _takeSnapshot() {
    _snapshot?.dispose();
    _snapshot = null;
    try {
      final box = _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      _snapshot = box?.toImageSync(pixelRatio: MediaQuery.devicePixelRatioOf(context));
    } catch (_) {
      // No snapshot: the pixels still cover and uncover the new screen.
    }
  }

  void _releaseSnapshotOnceCovered() {
    if (_snapshot != null && _c.value >= 0.5) {
      _snapshot!.dispose();
      _snapshot = null;
    }
  }

  // Random order per pixel with a little 2×2 clumping, so it does not read as static.
  void _shuffle(Size size) {
    _cols = (size.width / PixelDissolve.cell).ceil();
    final rows = (size.height / PixelDissolve.cell).ceil();
    final bc = (_cols / 2).ceil();
    final coarse = List.generate(bc * (rows / 2).ceil(), (_) => _rng.nextDouble());
    _order = Float32List(_cols * rows);
    _tone = Uint8List(_cols * rows);
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < _cols; x++) {
        final i = y * _cols + x;
        _order[i] = _rng.nextDouble() * .8 + coarse[(y >> 1) * bc + (x >> 1)] * .2;
        _tone[i] = _rng.nextDouble() < .62 ? 0 : (_rng.nextDouble() < .6 ? 1 : 2);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (_c.isAnimating)
          Positioned.fill(
            child: AbsorbPointer(
              child: CustomPaint(
                painter: _DissolvePainter(
                  progress: _c,
                  snapshot: () => _snapshot,
                  order: _order,
                  tone: _tone,
                  cols: _cols,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DissolvePainter extends CustomPainter {
  _DissolvePainter({
    required this.progress,
    required this.snapshot,
    required this.order,
    required this.tone,
    required this.cols,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final ui.Image? Function() snapshot;
  final Float32List order;
  final Uint8List tone;
  final int cols;

  @override
  void paint(Canvas canvas, Size size) {
    final (p, covering) = PixelDissolve.phase(progress.value);
    final shot = snapshot();
    if (covering && shot != null) {
      canvas.drawImageRect(
        shot,
        Rect.fromLTWH(0, 0, shot.width.toDouble(), shot.height.toDouble()),
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }

    const c = PixelDissolve.cell;
    final buckets = List.generate(4, (_) => <double>[]);
    for (var i = 0; i < order.length; i++) {
      final o = order[i];
      if (covering ? o >= p : o < p) continue;
      final isFresh = covering ? o > p - .07 : o < p + .07;
      buckets[isFresh ? 3 : tone[i]]
        ..add((i % cols) * c + c / 2)
        ..add((i ~/ cols) * c + c / 2);
    }
    for (var b = 0; b < 4; b++) {
      if (buckets[b].isEmpty) continue;
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.fromList(buckets[b]),
        Paint()
          ..color = b == 3 ? PixelDissolve.fresh : PixelDissolve.tones[b]
          ..strokeWidth = c + 0.5 // overlap a hair so no seams show between cells
          ..strokeCap = StrokeCap.square,
      );
    }
  }

  @override
  bool shouldRepaint(_DissolvePainter old) => old.order != order;
}
