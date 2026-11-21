import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'motion_kit.dart';

enum _Phase { idle, reveal, hide, roll }

/// Text that "decrypts": when [revealed] turns on, each masked dot cycles
/// through random glyphs before landing on the real character, left to right.
/// Hiding runs the same path backwards. With [rollOnChange], a new [text]
/// rolls in like a slot machine.
///
/// The random glyphs come from [Motion.glyphs] and never from [text].
class DecryptText extends StatefulWidget {
  const DecryptText({
    super.key,
    required this.text,
    required this.style,
    this.revealed = true,
    this.selectable = false,
    this.rollOnChange = false,
  });

  final String text;
  final TextStyle style;
  final bool revealed;
  final bool selectable;
  final bool rollOnChange;

  /// Mask shown while hidden: one dot per visible character, whitespace kept.
  static String mask(String text) => text.replaceAll(RegExp(r'\S'), '•');

  @override
  State<DecryptText> createState() => _DecryptTextState();
}

class _DecryptTextState extends State<DecryptText>
    with TickerProviderStateMixin, MotionClock {
  final _rng = math.Random();
  _Phase _phase = _Phase.idle;
  List<double> _start = const [];
  List<double> _settle = const [];
  double _total = 0;
  bool _animate = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = Motion.enabled(context);
  }

  @override
  void didUpdateWidget(DecryptText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      if (widget.rollOnChange && widget.revealed) {
        _begin(_Phase.roll);
      } else if (old.revealed != widget.revealed) {
        _begin(widget.revealed ? _Phase.reveal : _Phase.hide);
      } else {
        _end();
      }
    } else if (old.revealed != widget.revealed) {
      _begin(widget.revealed ? _Phase.reveal : _Phase.hide);
    }
  }

  void _begin(_Phase phase) {
    if (!_animate || widget.text.isEmpty) {
      _end();
      return;
    }
    final n = widget.text.length;
    final roll = phase == _Phase.roll;
    // Keep long secrets short: the whole wave fits in roughly half a second.
    final stagger = roll ? math.min(0.035, 0.5 / n) : math.min(0.03, 0.35 / n);
    final lead = roll ? 0.12 : 0.0;
    _start = List.generate(n, (i) => lead + i * stagger);
    _settle = List.generate(n, (i) => _start[i] + 0.14 + _rng.nextDouble() * 0.22);
    _total = _settle.reduce(math.max);
    _phase = phase;
    restartClock();
    setState(() {});
  }

  void _end() {
    stopClock();
    if (_phase != _Phase.idle) setState(() => _phase = _Phase.idle);
  }

  @override
  void onTick(double t) {
    if (t > _total) _end();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.idle) {
      if (!widget.revealed) {
        return Text(DecryptText.mask(widget.text),
            style: widget.style.copyWith(color: AppColors.textSecondary));
      }
      return widget.selectable
          ? SelectableText(widget.text, style: widget.style)
          : Text(widget.text, style: widget.style);
    }
    return ValueListenableBuilder<double>(
      valueListenable: time,
      builder: (context, t, _) => Text.rich(_spans(t)),
    );
  }

  TextSpan _spans(double t) {
    final plain = widget.style;
    final masked = plain.copyWith(color: AppColors.textSecondary);
    final scrambled = plain.copyWith(color: AppColors.accent);
    final text = widget.text;
    final step = (t * 22).floor();
    final spans = <TextSpan>[];
    final buf = StringBuffer();
    TextStyle? current;

    void flush() {
      if (buf.isNotEmpty) spans.add(TextSpan(text: buf.toString(), style: current));
      buf.clear();
    }

    for (var i = 0; i < text.length; i++) {
      final real = text[i];
      String ch;
      TextStyle style;
      if (real.trim().isEmpty) {
        ch = real;
        style = current ?? plain;
      } else {
        final before = t < _start[i], during = !before && t < _settle[i];
        switch (_phase) {
          case _Phase.reveal:
            (ch, style) = before ? ('•', masked) : during ? (Motion.glyph(i, step), scrambled) : (real, plain);
          case _Phase.hide:
            (ch, style) = before ? (real, plain) : during ? (Motion.glyph(i, step), scrambled) : ('•', masked);
          case _Phase.roll:
            (ch, style) = before || during ? (Motion.glyph(i, step), scrambled) : (real, plain);
          case _Phase.idle:
            (ch, style) = (real, plain);
        }
      }
      if (style != current) {
        flush();
        current = style;
      }
      buf.write(ch);
    }
    flush();
    return TextSpan(children: spans);
  }
}
