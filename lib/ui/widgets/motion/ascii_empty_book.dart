import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'motion_kit.dart';

/// An open ASCII book with blank pages: a page turns by itself every few
/// seconds while dust motes drift up. Shown when the vault is empty.
class AsciiEmptyBook extends StatefulWidget {
  const AsciiEmptyBook({super.key, this.fontSize = 10});

  final double fontSize;

  @override
  State<AsciiEmptyBook> createState() => _AsciiEmptyBookState();
}

class _Mote {
  _Mote(this.x, this.y, this.speed, this.phase);
  double x, y;
  final double speed, phase;
}

class _AsciiEmptyBookState extends State<AsciiEmptyBook>
    with TickerProviderStateMixin, MotionClock {
  static const cols = 50, rows = 16;
  late final GlyphCache _glyphs;
  final _rng = math.Random();
  late final List<_Mote> _motes;
  double _last = 0;
  bool _animate = true;

  @override
  void initState() {
    super.initState();
    _glyphs = GlyphCache(Motion.mono(fontSize: widget.fontSize, height: 1.2))
      ..onFontsChanged = () {
        if (mounted) setState(() {});
      };
    _motes = List.generate(
      9,
      (_) => _Mote(3 + _rng.nextDouble() * 44, _rng.nextDouble() * rows,
          0.35 + _rng.nextDouble() * 0.5, _rng.nextDouble() * 6),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = Motion.enabled(context);
    _animate ? startClock() : stopClock();
  }

  @override
  void onTick(double t) {
    final dt = (t - _last).clamp(0.0, 0.05);
    _last = t;
    for (final m in _motes) {
      m.y -= m.speed * dt;
      if (m.y < 0) {
        m.y = rows - 0.01;
        m.x = 3 + _rng.nextDouble() * 44;
      }
    }
  }

  @override
  void dispose() {
    _glyphs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cell = _glyphs.cell;
    return RepaintBoundary(
      child: SizedBox(
        width: cols * cell.width,
        height: rows * cell.height,
        child: CustomPaint(
          painter: _BookPainter(
            glyphs: _glyphs,
            time: time,
            motes: _animate ? _motes : const [],
          ),
        ),
      ),
    );
  }
}

class _BookPainter extends CustomPainter {
  _BookPainter({required this.glyphs, required this.time, required this.motes})
      : super(repaint: time);

  static const cols = _AsciiEmptyBookState.cols, rows = _AsciiEmptyBookState.rows;
  static const sx = 25, pw = 16, y0 = 5, y1 = 11, cycle = 5.4;

  final GlyphCache glyphs;
  final ValueNotifier<double> time;
  final List<_Mote> motes;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = glyphs.cell;
    final chars = List<String?>.filled(cols * rows, null);
    final colors = List<Color>.filled(cols * rows, AppColors.textSecondary);
    void put(int c, int r, String ch, Color color) {
      if (c < 0 || r < 0 || c >= cols || r >= rows) return;
      chars[r * cols + c] = ch;
      colors[r * cols + c] = color;
    }

    // The book: two blank pages, a spine and the cover edge.
    const line = AppColors.textSecondary, faint = AppColors.textDisabled;
    for (var c = sx - pw + 1; c < sx + pw; c++) {
      if (c == sx) continue;
      put(c, y0, '_', line);
      put(c, y1, '_', line);
    }
    for (var r = y0 + 1; r <= y1; r++) {
      put(sx - pw, r, '|', line);
      put(sx, r, '|', line);
      put(sx + pw, r, '|', line);
    }
    for (var c = sx - pw; c <= sx + pw; c++) {
      put(c, y1 + 1, '-', faint);
    }
    for (final c in [sx - pw, sx, sx + pw]) {
      put(c, y1 + 1, "'", faint);
    }

    // The turning page: a quad hinged on the spine, lifted as it crosses.
    final t = time.value;
    final tp = ((t % cycle - 0.5) / 1.9).clamp(0.0, 1.0);
    if (tp > 0 && tp < 1) {
      final e = tp < 0.5 ? 2 * tp * tp : 1 - math.pow(-2 * tp + 2, 2) / 2;
      final th = e * math.pi, lift = math.sin(th) * 2.6, px = sx + 0.5 + math.cos(th) * pw;
      const a = Offset(sx + 0.5, y0 + 0.95);
      final b = Offset(px, y0 + 0.95 - lift);
      final cc = Offset(px, y1 + 0.95 - lift * 0.45);
      const d = Offset(sx + 0.5, y1 + 0.95);
      final page = Path()..addPolygon([a, b, cc, d], true);
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          if (page.contains(Offset(c + 0.5, r + 0.5))) chars[r * cols + c] = null;
        }
      }
      void seg(Offset p, Offset q) {
        final dx = q.dx - p.dx, dy = q.dy - p.dy;
        var ang = math.atan2(-(dy * cell.height), dx * cell.width) * 180 / math.pi;
        if (ang > 90) ang -= 180;
        if (ang <= -90) ang += 180;
        final ch = ang.abs() < 20 ? '_' : ang.abs() > 70 ? '|' : ang > 0 ? '/' : r'\';
        final n = (math.max(dx.abs(), dy.abs()) * 2).ceil() + 1;
        for (var i = 0; i <= n; i++) {
          put((p.dx + dx * i / n).floor(), (p.dy + dy * i / n).floor(), ch, AppColors.accent);
        }
      }
      seg(a, b);
      seg(b, cc);
      seg(cc, d);
    }

    // Dust, kept off the book.
    for (final m in motes) {
      final c = (m.x + math.sin(t * 0.8 + m.phase) * 1.2).floor(), r = m.y.floor();
      if (c >= sx - pw && c <= sx + pw && r >= y0 && r <= y1 + 1) continue;
      if (c < 0 || c >= cols || r < 0 || r >= rows || chars[r * cols + c] != null) continue;
      put(c, r, (t * 2 + m.phase).floor() % 3 == 0 ? '·' : '.', faint);
    }

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final ch = chars[r * cols + c];
        if (ch != null) {
          glyphs.paint(canvas, ch, colors[r * cols + c], Offset(c * cell.width, r * cell.height));
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BookPainter old) => old.glyphs != glyphs || old.motes != motes;
}
