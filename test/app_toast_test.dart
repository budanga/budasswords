import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:budasswords/core/utils/app_toast.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<double> toastBottom(WidgetTester tester, double keyboardHeight) async {
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => AppToast.error(context, 'Contraseña incorrecta'),
          child: const Text('go'),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    final bottom = tester.getBottomLeft(find.text('Contraseña incorrecta')).dy;
    await tester.pumpAndSettle(const Duration(seconds: 3)); // let the toast expire
    return bottom;
  }

  testWidgets('error toast sits above the keyboard and returns when it closes',
      (tester) async {
    final withoutKeyboard = await toastBottom(tester, 0);
    final keyboardPx = 300 * tester.view.devicePixelRatio;
    final withKeyboard = await toastBottom(tester, keyboardPx);

    expect(withoutKeyboard - withKeyboard, closeTo(300, 0.5));
  });
}
