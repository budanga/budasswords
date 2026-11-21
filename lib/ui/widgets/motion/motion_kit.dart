import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:budasswords/core/constants/app_colors.dart';

/// Shared pieces for the ASCII and dither animations.
///
/// Rule of thumb: ASCII for data and encryption moments, dither for time and
/// transitions.
abstract class Motion {
  /// Glyphs used while something "decrypts". Never derived from a secret.
  static const glyphs = r'0123456789abcdef#$%&*+=<>/\|{}[]?!~^';

  /// Deterministic pseudo-random glyph for cell [i] at animation step [step].
  static String glyph(int i, int step) {
    final h = ((i + 1) * 2654435761) ^ ((step + 7) * 40503);
    return glyphs[(h & 0x7fffffff) % glyphs.length];
  }

  /// False when the user asked the OS to reduce motion.
  static bool enabled(BuildContext context) =>
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  /// The monospace face for every ASCII surface (IBM Plex Mono).
  static TextStyle mono({
    double fontSize = 14,
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w500,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
      );
}

/// Ordered-dither threshold matrix with values in (0, 1).
class Bayer {
  Bayer._(this.size, this._m);

  /// Builds a 2^[bits] square matrix (bits = 2 → 4×4, bits = 3 → 8×8).
  factory Bayer(int bits) {
    final size = 1 << bits;
    final m = List<double>.filled(size * size, 0);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        var v = 0;
        for (var i = 0; i < bits; i++) {
          final xb = (x >> i) & 1, yb = (y >> i) & 1;
          v |= (((xb ^ yb) << 1) | yb) << (2 * (bits - 1 - i));
        }
        m[y * size + x] = (v + 0.5) / (size * size);
      }
    }
    return Bayer._(size, m);
  }

  static final b4 = Bayer(2);
  static final b8 = Bayer(3);

  final int size;
  final List<double> _m;

  double at(int x, int y) => _m[(y % size) * size + (x % size)];
}

/// Caches single-glyph [TextPainter]s so ASCII painters can draw hundreds of
/// cells per frame without laying text out again. Rebuilds itself when a font
/// finishes loading.
class GlyphCache {
  GlyphCache(this.style) {
    PaintingBinding.instance.systemFonts.addListener(_reset);
  }

  final TextStyle style;
  final _painters = <int, TextPainter>{};
  Size? _cell;

  /// Size of one monospace cell (advance width × line height).
  Size get cell => _cell ??= _measure();

  /// Called after a font change, so owners can resize.
  VoidCallback? onFontsChanged;

  void paint(Canvas canvas, String ch, Color color, Offset offset) {
    final key = (color.toARGB32() << 16) | ch.codeUnitAt(0);
    final tp = _painters.putIfAbsent(key, () => _layout(ch, color));
    tp.paint(canvas, offset);
  }

  TextPainter _layout(String ch, Color color) => TextPainter(
        text: TextSpan(text: ch, style: style.copyWith(color: color)),
        textDirection: TextDirection.ltr,
      )..layout();

  Size _measure() {
    final tp = _layout('M', const Color(0xFF000000));
    final size = Size(tp.width, (style.fontSize ?? 14) * (style.height ?? 1.0));
    tp.dispose();
    return size;
  }

  void _reset() {
    for (final tp in _painters.values) {
      tp.dispose();
    }
    _painters.clear();
    _cell = null;
    onFontsChanged?.call();
  }

  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_reset);
    for (final tp in _painters.values) {
      tp.dispose();
    }
    _painters.clear();
  }
}

/// Seconds since the ticker started, for painters that repaint every frame.
mixin MotionClock<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  final time = ValueNotifier<double>(0);
  Ticker? _ticker;

  /// Override to update per-frame state before painting.
  void onTick(double seconds) {}

  void startClock() {
    _ticker ??= createTicker((elapsed) {
      final s = elapsed.inMicroseconds / 1e6;
      onTick(s);
      time.value = s;
    });
    if (!_ticker!.isActive) _ticker!.start();
  }

  void stopClock() => _ticker?.stop();

  /// Starts again from zero seconds.
  void restartClock() {
    stopClock();
    time.value = 0;
    startClock();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    time.dispose();
    super.dispose();
  }
}
