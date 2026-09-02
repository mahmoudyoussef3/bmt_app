import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bmt_app/landing/presentation/landing_page.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: LandingPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  // A width sweep rather than a handful of breakpoints: the overflows this
  // page produced were all narrow bands a few pixels wide — a card wrapping to
  // one more line than its row was measured for, a header whose logo and
  // buttons stopped fitting — and picking five sizes walked straight past
  // them. Every width is scrolled end to end so each section actually lays out.
  testWidgets('lays out with no overflow at any width', (tester) async {
    final failures = <String>[];
    for (var width = 320.0; width <= 1600; width += 16) {
      await pumpAt(tester, Size(width, 1000));
      if (tester.takeException() != null) {
        failures.add('${width.toInt()}: build');
        continue;
      }
      final scrollable = find.byType(Scrollable).first;
      for (var step = 0; step < 32; step++) {
        await tester.drag(scrollable, const Offset(0, -900));
        await tester.pump(const Duration(milliseconds: 30));
        if (tester.takeException() != null) {
          failures.add('${width.toInt()}: scroll step $step');
          break;
        }
      }
    }
    expect(failures, isEmpty);
  });

  testWidgets('dashboard tabs and faq respond', (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    final scrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.text('المالية'),
      400,
      scrollable: scrollable,
      maxScrolls: 60,
    );
    await tester.tap(find.text('المالية'));
    await tester.pump(const Duration(milliseconds: 400));
    // Each tab swaps the console capture and the line describing it.
    expect(
      find.text('التحصيل والمدفوعات والمصروفات، ومنين جه كل جنيه.'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('هل يوجد تطبيق للكابتن؟'),
      400,
      scrollable: scrollable,
      maxScrolls: 80,
    );
    await tester.tap(find.text('هل يوجد تطبيق للكابتن؟'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });
}
