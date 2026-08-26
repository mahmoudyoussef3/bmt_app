import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/core/widgets/client_step_progress.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_progress_bar.dart';

import '../../client_test_app.dart';

/// The header's whole job is to be read at a glance, so its geometry is the
/// behaviour worth pinning: the step a rider is on has to sit under its own
/// name, and the rail between markers has to look like one rule rather than
/// six differently-sized ones. Both broke when a long label was allowed to
/// decide how wide its own step was.
void main() {
  Future<void> pumpHeader(
    WidgetTester tester,
    int step, {
    TextDirection direction = TextDirection.rtl,
  }) async {
    await tester.binding.setSurfaceSize(const Size(375, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      clientTestApp(
        Scaffold(
          body: Directionality(
            textDirection: direction,
            child: WizardProgressBar(step: step),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<double> labelCentres(WidgetTester tester) {
    final labels = find.descendant(
      of: find.byType(ClientStepProgress),
      matching: find.byType(Text),
    );
    return [
      for (var i = 0; i < tester.widgetList(labels).length; i++)
        if (tester.widget<Text>(labels.at(i)).data!.length > 1)
          tester.getCenter(labels.at(i)).dx,
    ];
  }

  testWidgets('spaces every step evenly, whichever step is showing', (
    tester,
  ) async {
    for (final step in [0, 3, 5]) {
      await pumpHeader(tester, step);

      final centres = labelCentres(tester);
      expect(centres, hasLength(6));

      final gaps = [
        for (var i = 1; i < centres.length; i++)
          (centres[i] - centres[i - 1]).abs(),
      ];
      for (final gap in gaps) {
        expect(
          gap,
          closeTo(gaps.first, 0.5),
          reason: 'step $step: columns are not equal width',
        );
      }
    }
  });

  testWidgets('marks the steps behind the rider as done', (tester) async {
    await pumpHeader(tester, 4);

    // Four checks behind, and the two ahead still carry their number.
    expect(
      find.descendant(
        of: find.byType(ClientStepProgress),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsNWidgets(4),
    );
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('runs step one to the start edge in both directions', (
    tester,
  ) async {
    await pumpHeader(tester, 0);
    final rtl = labelCentres(tester);
    // Right-to-left: step one is the rightmost column.
    expect(rtl.first, greaterThan(rtl.last));

    await pumpHeader(tester, 0, direction: TextDirection.ltr);
    final ltr = labelCentres(tester);
    expect(ltr.first, lessThan(ltr.last));
  });
}
