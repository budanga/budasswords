import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'motion_kit.dart';

/// One character of the ASCII logo.
class ShieldCell {
  const ShieldCell(this.col, this.row, this.char, this.color);
  final int col;
  final int row;
  final String char;
  final Color color;
}

/// The launcher logo (shackle + two-tone shield + keyhole) sampled into an
/// ASCII grid. Uses the same 1024px design space as [AppLogo].
abstract class ShieldGrid {
  static const cols = 32; // just wide enough for the shield, no empty margins
  static const rows = 26;
  static const ramp = ' .:-=+*#%@';
  static const shade = Color(0xFF9E4A2E);

  static final List<ShieldCell> cells = _sample();

  static List<ShieldCell> _sample() {
    // Grid in a 6×10 px-per-cell space, which matches a monospace cell (0.6 em × 1 em).
    const cw = 6.0, ch = 10.0, wm = cols * cw, hm = rows * ch;
    const bx = 296.0, by = 211.0, bw = 432.0, bh = 625.0;
    final s = math.min((wm - 8) / bw, (hm - 8) / bh);
    final offX = (wm - bw * s) / 2, offY = (hm - bh * s) / 2;

    final left = Path()
      ..moveTo(512, 400)
      ..lineTo(296, 450)
      ..lineTo(296, 600)
      ..quadraticBezierTo(300, 736, 512, 836)
      ..close();
    final right = Path()
      ..moveTo(512, 400)
      ..lineTo(728, 450)
      ..lineTo(728, 600)
      ..quadraticBezierTo(724, 736, 512, 836)
      ..close();
    final inner = Path()
      ..moveTo(512, 452)
      ..lineTo(344, 490)
      ..lineTo(344, 598)
      ..quadraticBezierTo(348, 702, 512, 782)
      ..quadraticBezierTo(676, 702, 680, 598)
      ..lineTo(680, 490)
      ..close();
    // The engraved inner rule: inside a slightly grown copy, outside a shrunk one.
    Path scaled(double k) {
      const c = Offset(512, 617);
      return inner.transform(Float64List.fromList([
        k, 0, 0, 0, //
        0, k, 0, 0,
        0, 0, 1, 0,
        c.dx * (1 - k), c.dy * (1 - k), 0, 1,
      ]));
    }
    final ruleOuter = scaled(1 + 11 / 168), ruleInner = scaled(1 - 11 / 168);
    final keyTrap = Path()
      ..moveTo(492, 600)
      ..lineTo(472, 690)
      ..lineTo(552, 690)
      ..lineTo(532, 600)
      ..close();

    bool inShackle(double x, double y) {
      var d = double.infinity;
      if (y >= 360 && y <= 455) d = math.min((x - 392).abs(), (x - 632).abs());
      if (y <= 360) d = math.min(d, ((Offset(x, y) - const Offset(512, 360)).distance - 120).abs());
      return d <= 29;
    }

    // 0 = empty, 1 = shackle, 2 = shield left, 3 = shield right
    int classify(double x, double y) {
      final p = Offset(x, y);
      if ((p - const Offset(512, 582)).distance <= 40 || keyTrap.contains(p)) return 0;
      if (ruleOuter.contains(p) && !ruleInner.contains(p)) return 0;
      if (left.contains(p)) return 2;
      if (right.contains(p)) return 3;
      if (inShackle(x, y)) return 1;
      return 0;
    }

    const sx = 3, sy = 5;
    final out = <ShieldCell>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final counts = [0, 0, 0, 0];
        for (var j = 0; j < sy; j++) {
          for (var i = 0; i < sx; i++) {
            final px = c * cw + (i + 0.5) * cw / sx;
            final py = r * ch + (j + 0.5) * ch / sy;
            counts[classify(bx + (px - offX) / s, by + (py - offY) / s)]++;
          }
        }
        final cov = (counts[1] + counts[2] + counts[3]) / (sx * sy);
        if (cov < 0.07) continue;
        final Color color;
        if (counts[1] >= counts[2] && counts[1] >= counts[3]) {
          color = AppColors.textPrimary;
        } else if (counts[2] >= counts[3]) {
          color = AppColors.accent;
        } else {
          color = shade;
        }
        final light = color == AppColors.accent ? 0.84 : 1.0;
        final idx = (cov * light * (ramp.length - 1)).round().clamp(1, ramp.length - 1);
        out.add(ShieldCell(c, r, ramp[idx], color));
      }
    }
    return out;
  }
}

/// The logo assembling itself from random glyphs, top to bottom, as if it
/// were being decrypted. Once resolved it stays alive with a rare flicker.
class AsciiShield extends StatefulWidget {
  const AsciiShield({super.key, this.fontSize = 13});

  final double fontSize;

  @override
  State<AsciiShield> createState() => _AsciiShieldState();
}

class _AsciiShieldState extends State<AsciiShield>
    with TickerProviderStateMixin, MotionClock {
  late final GlyphCache _glyphs;
  late final List<double> _delay;
  late final List<double> _glitch;
  final _rng = math.Random();
  bool _animate = true;

  @override
  void initState() {
    super.initState();
    _glyphs = GlyphCache(Motion.mono(fontSize: widget.fontSize, height: 1.0))
      ..onFontsChanged = () {
        if (mounted) setState(() {});
      };
    final cells = ShieldGrid.cells;
    _delay = [
      for (final c in cells) 0.15 + (c.row / ShieldGrid.rows) * 0.6 + _rng.nextDouble() * 0.3,
    ];
    _glitch = List.filled(cells.length, 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = Motion.enabled(context);
    _animate ? startClock() : stopClock();
  }

  @override
  void onTick(double t) {
    if (t < 1.2) return;
    for (var i = 0; i < _glitch.length; i++) {
      if (_glitch[i] < t && _rng.nextDouble() < 0.0002) _glitch[i] = t + 0.09;
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
        width: ShieldGrid.cols * cell.width,
        height: ShieldGrid.rows * cell.height,
        child: CustomPaint(
          painter: _ShieldPainter(
            glyphs: _glyphs,
            time: time,
            delay: _delay,
            glitch: _glitch,
            animate: _animate,
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  _ShieldPainter({
    required this.glyphs,
    required this.time,
    required this.delay,
    required this.glitch,
    required this.animate,
  }) : super(repaint: time);

  final GlyphCache glyphs;
  final ValueNotifier<double> time;
  final List<double> delay;
  final List<double> glitch;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = glyphs.cell;
    final t = animate ? time.value : 99.0;
    final step = (t * 16).floor();
    final cells = ShieldGrid.cells;
    for (var i = 0; i < cells.length; i++) {
      final k = cells[i];
      String ch;
      Color color;
      if (t < delay[i] - 0.3) {
        continue;
      } else if (t < delay[i]) {
        ch = Motion.glyph(i, step);
        color = AppColors.textDisabled;
      } else if (glitch[i] > t) {
        ch = Motion.glyph(i, step + 3);
        color = AppColors.accentSoft;
      } else {
        ch = k.char;
        color = k.color;
      }
      glyphs.paint(canvas, ch, color, Offset(k.col * cell.width, k.row * cell.height));
    }
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.animate != animate || old.glyphs != glyphs;
}
