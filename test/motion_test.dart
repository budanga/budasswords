import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/core/utils/app_toast.dart';
import 'package:budasswords/core/utils/password_strength.dart';
import 'package:budasswords/ui/widgets/motion/ascii_shield.dart';
import 'package:budasswords/ui/widgets/motion/decrypt_text.dart';
import 'package:budasswords/ui/widgets/motion/dither_bar.dart';
import 'package:budasswords/ui/widgets/motion/dither_cloud.dart';
import 'package:budasswords/ui/widgets/motion/dither_paper.dart';
import 'package:budasswords/ui/widgets/motion/motion_kit.dart';
import 'package:budasswords/ui/widgets/motion/pixel_dissolve.dart';

String rendered(WidgetTester tester) {
  final rich = tester.widgetList<RichText>(find.byType(RichText)).first;
  return rich.text.toPlainText();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('PixelDissolve', () {
    final dissolving = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter.runtimeType.toString() == '_DissolvePainter');

    Widget app(bool open, {bool reduceMotion = false}) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: const Size(400, 800), disableAnimations: reduceMotion),
            child: PixelDissolve(
              open: open,
              child: Scaffold(body: Text(open ? 'vault' : 'login')),
            ),
          ),
        );

    test('pixels appear, hold fully covered, then go out', () {
      expect(PixelDissolve.phase(0), (0.0, true));
      expect(PixelDissolve.phase(0.5), (1.0, true));
      expect(PixelDissolve.phase(1), (1.0, false));
      final (p, covering) = PixelDissolve.phase(0.75);
      expect(covering, isFalse);
      expect(p, inExclusiveRange(0, 1));
    });

    testWidgets('opening the vault plays once, blocking taps, then clears', (tester) async {
      await tester.pumpWidget(app(false));
      expect(dissolving, findsNothing);

      await tester.pumpWidget(app(true));
      await tester.pump(const Duration(milliseconds: 400));
      expect(dissolving, findsOneWidget);
      expect(find.descendant(of: find.byType(PixelDissolve), matching: find.byType(AbsorbPointer)), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump();
      expect(dissolving, findsNothing);
      expect(find.text('vault'), findsOneWidget);
    });

    testWidgets('locking in the background does not animate', (tester) async {
      await tester.pumpWidget(app(true));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      addTearDown(() => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
      await tester.pumpWidget(app(false));
      await tester.pump(const Duration(milliseconds: 100));
      expect(dissolving, findsNothing);
    });

    testWidgets('does not animate when the OS reduces motion', (tester) async {
      await tester.pumpWidget(app(false, reduceMotion: true));
      await tester.pumpWidget(app(true, reduceMotion: true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(dissolving, findsNothing);
    });
  });

  group('Bayer', () {
    test('4×4 matrix is the standard ordered-dither matrix', () {
      const expected = [
        [0, 8, 2, 10],
        [12, 4, 14, 6],
        [3, 11, 1, 9],
        [15, 7, 13, 5],
      ];
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          expect(Bayer.b4.at(x, y), (expected[y][x] + 0.5) / 16);
        }
      }
    });

    test('8×8 matrix uses every threshold once', () {
      final values = {for (var y = 0; y < 8; y++) for (var x = 0; x < 8; x++) Bayer.b8.at(x, y)};
      expect(values.length, 64);
    });
  });

  group('PasswordStrength', () {
    // The generator's full pool: 26 + 26 + 10 + 26 symbols.
    const pool = 88;
    test('grades by entropy bits', () {
      expect(PasswordStrength.of(length: 8, poolSize: pool).level, StrengthLevel.fair);
      expect(PasswordStrength.of(length: 16, poolSize: pool).level, StrengthLevel.strong);
      expect(PasswordStrength.of(length: 20, poolSize: pool).level, StrengthLevel.veryStrong);
      expect(PasswordStrength.of(length: 8, poolSize: 10).level, StrengthLevel.weak);
    });

    test('an empty pool has no entropy', () {
      final s = PasswordStrength.of(length: 20, poolSize: 0);
      expect(s.bits, 0);
      expect(s.fraction, 0);
    });

    test('bits are length × log2(pool)', () {
      expect(PasswordStrength.of(length: 16, poolSize: 88).bits, 103);
    });
  });

  group('DitherBar', () {
    test('empty and full ends', () {
      for (var cx = 0; cx < 100; cx++) {
        for (var cy = 0; cy < 4; cy++) {
          expect(DitherBarPainter.lit(cx, cy, 100, 0, 16), isFalse);
          expect(DitherBarPainter.lit(cx, cy, 100, 1, 16), isTrue);
        }
      }
    });

    test('half full lights the left side only', () {
      bool col(int cx) => List.generate(4, (cy) => DitherBarPainter.lit(cx, cy, 100, 0.5, 16)).any((l) => l);
      expect(col(10), isTrue);
      expect(col(90), isFalse);
    });
  });

  test('ASCII shield samples the shackle and both shield halves', () {
    final colors = ShieldGrid.cells.map((c) => c.color).toSet();
    expect(colors, containsAll([AppColors.textPrimary, AppColors.accent, ShieldGrid.shade]));
    expect(ShieldGrid.cells.length, greaterThan(300));
  });

  test('cloud silhouette and paper frame are well formed', () {
    expect(DitherCloud.mask, isNotEmpty);
    final px = DitherPaper.frame(20, 30, 0);
    expect(px.length, 20 * 30 * 4);
    expect(px.every((b) => b >= 0 && b <= 255), isTrue);
  });

  test('scramble glyphs are deterministic and from the glyph set', () {
    expect(Motion.glyph(3, 9), Motion.glyph(3, 9));
    for (var i = 0; i < 200; i++) {
      expect(Motion.glyphs.contains(Motion.glyph(i, i * 7)), isTrue);
    }
  });

  group('DecryptText', () {
    const sample = 'texto de ejemplo';

    Widget host(bool revealed, {bool reduceMotion = false}) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Scaffold(
              body: DecryptText(text: sample, revealed: revealed, style: const TextStyle(fontSize: 14)),
            ),
          ),
        );

    testWidgets('masks while hidden, scrambles, then shows the real text', (tester) async {
      await tester.pumpWidget(host(false));
      expect(find.text(DecryptText.mask(sample)), findsOneWidget);
      expect(find.textContaining('texto'), findsNothing);

      await tester.pumpWidget(host(true));
      await tester.pump(const Duration(milliseconds: 160));
      final mid = rendered(tester);
      expect(mid.length, sample.length);
      expect(mid, isNot(sample));
      expect(mid, isNot(DecryptText.mask(sample)));

      await tester.pump(const Duration(seconds: 1));
      expect(find.text(sample), findsOneWidget);
    });

    testWidgets('hides again through the scramble back to dots', (tester) async {
      await tester.pumpWidget(host(true));
      await tester.pumpWidget(host(false));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(DecryptText.mask(sample)), findsOneWidget);
    });

    testWidgets('switches instantly when the OS reduces motion', (tester) async {
      await tester.pumpWidget(host(false, reduceMotion: true));
      await tester.pumpWidget(host(true, reduceMotion: true));
      await tester.pump();
      expect(find.text(sample), findsOneWidget);
    });

    test('mask keeps whitespace and line breaks', () {
      expect(DecryptText.mask('ab c\nd'), '•• •\n•');
    });
  });

  testWidgets('countdown toast counts down and dismisses on tap', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => AppToast.countdown(
            context,
            message: (s) => 'Se borra en ${s}s',
            duration: const Duration(seconds: 30),
          ),
          child: const Text('go'),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.text('Se borra en 30s'), findsOneWidget);
    expect(find.byType(DitherBar), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 16)); // first tick starts the countdown
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Se borra en 20s'), findsOneWidget);

    await tester.tap(find.text('Se borra en 20s'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Se borra en'), findsNothing);
  });
}
