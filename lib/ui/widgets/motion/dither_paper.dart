import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'motion_kit.dart';

/// A faint glow moving slowly over the parchment, drawn with an 8×8 Bayer
/// dither in 4px cells, like light on paper. Renders at 12 fps into a small
/// image; stays still when the OS asks to reduce motion.
class DitherPaper extends StatefulWidget {
  const DitherPaper({super.key});

  static const cellSize = 4.0;
  static const fps = 12;

  // bg0, then two warm tints of the accent.
  static const _tones = [0xFFF5F2EB, 0xFFEFE1D7, 0xFFE7CABC];

  /// RGBA pixels for a [cols]×[rows] frame at time [t] seconds.
  static Uint8List frame(int cols, int rows, double t) {
    final px = Uint8List(cols * rows * 4);
    final gx = 0.5 + 0.26 * math.sin(t * 0.13), gy = 0.34 + 0.14 * math.cos(t * 0.1);
    final gx2 = 0.5 - 0.3 * math.sin(t * 0.09 + 1);
    const gy2 = 0.85;
    final aspect = rows / cols;
    for (var y = 0; y < rows; y++) {
      final ny = y / rows;
      for (var x = 0; x < cols; x++) {
        final nx = x / cols;
        final d1 = math.pow(nx - gx, 2) + math.pow((ny - gy) * aspect * 0.76, 2);
        final d2 = math.pow(nx - gx2, 2) + math.pow((ny - gy2) * aspect * 0.76, 2);
        final v = (0.9 * math.exp(-d1 / 0.05) + 0.55 * math.exp(-d2 / 0.04) + 0.12 * ny).clamp(0.0, 1.0);
        final q = v * 2, base = q.floor();
        final idx = math.min(2, base + ((q - base) > Bayer.b8.at(x, y) ? 1 : 0));
        final c = _tones[idx], o = (y * cols + x) * 4;
        px[o] = (c >> 16) & 0xFF;
        px[o + 1] = (c >> 8) & 0xFF;
        px[o + 2] = c & 0xFF;
        px[o + 3] = 0xFF;
      }
    }
    return px;
  }

  @override
  State<DitherPaper> createState() => _DitherPaperState();
}

class _DitherPaperState extends State<DitherPaper>
    with TickerProviderStateMixin, MotionClock {
  ui.Image? _image;
  Size _size = Size.zero;
  Size _rendered = Size.zero;
  int _lastStep = -1;
  bool _busy = false;
  bool _animate = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = Motion.enabled(context);
    _animate ? startClock() : stopClock();
  }

  @override
  void onTick(double t) {
    final step = (t * DitherPaper.fps).floor();
    if (step != _lastStep) {
      _lastStep = step;
      _render(t);
    }
  }

  void _render(double t) {
    if (_busy || _size.isEmpty) return;
    _busy = true;
    final size = _size;
    final cols = (size.width / DitherPaper.cellSize).ceil();
    final rows = (size.height / DitherPaper.cellSize).ceil();
    ui.decodeImageFromPixels(DitherPaper.frame(cols, rows, t), cols, rows, ui.PixelFormat.rgba8888, (img) {
      _busy = false;
      if (!mounted) {
        img.dispose();
        return;
      }
      setState(() {
        _image?.dispose();
        _image = img;
        _rendered = size;
      });
    });
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = constraints.biggest;
      // Still mode: draw one frame, and again if the size changes.
      if (!_animate && _rendered != _size) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _render(20);
        });
      }
      return RepaintBoundary(
        child: RawImage(
          image: _image,
          width: _size.width,
          height: _size.height,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.none,
        ),
      );
    });
  }
}
