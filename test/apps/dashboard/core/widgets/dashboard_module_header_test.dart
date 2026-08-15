import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';

/// Mounts [child] in the real dashboard theme and RTL, the way every module
/// renders it.
Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: DashboardAppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pressToggle(WidgetTester tester) async {
  await tester.tap(find.text('الملخص'));
  await tester.pumpAndSettle();
}

DashboardModuleHeader _header({
  Widget? summary,
  Widget? pinned,
  Widget? collapsedSummary,
  String? sectionId,
  List<Widget> actions = const [],
}) {
  return DashboardModuleHeader(
    icon: Icons.directions_bus_rounded,
    title: 'إدارة الرحلات',
    subtitle: 'تابع حركة الرحلات، الإشغال، والطاقم من مساحة عمل واحدة.',
    actions: actions,
    sectionId: sectionId,
    collapsedSummary: collapsedSummary,
    summary: summary,
    pinned: pinned,
  );
}

void main() {
  setUp(DashboardSectionStateStore.instance.clear);

  group('DashboardModuleHeader', () {
    testWidgets('identity is always readable', (tester) async {
      await _pump(tester, _header(summary: const Text('الأرقام')));

      expect(find.text('إدارة الرحلات'), findsOneWidget);
      expect(
        find.text('تابع حركة الرحلات، الإشغال، والطاقم من مساحة عمل واحدة.'),
        findsOneWidget,
      );
    });

    testWidgets('the summary starts folded and the toggle opens it', (
      tester,
    ) async {
      await _pump(tester, _header(summary: const Text('الأرقام')));

      // Not merely offstage on first view: a folded summary is never built, so
      // a module pays nothing for figures the operator has not asked for.
      expect(find.text('الأرقام'), findsNothing);

      await _pressToggle(tester);
      expect(find.text('الأرقام'), findsOneWidget);

      await _pressToggle(tester);
      expect(find.text('الأرقام'), findsNothing);
    });

    testWidgets('pressing an action never folds or unfolds', (tester) async {
      var pressed = 0;
      await _pump(
        tester,
        _header(
          summary: const Text('الأرقام'),
          actions: [
            FilledButton(
              onPressed: () => pressed++,
              child: const Text('رحلة جديدة'),
            ),
          ],
        ),
      );

      await tester.tap(find.text('رحلة جديدة'));
      await tester.pumpAndSettle();

      expect(pressed, 1);
      expect(find.text('الأرقام'), findsNothing);
    });

    testWidgets('a pinned body is on screen with the summary folded', (
      tester,
    ) async {
      await _pump(
        tester,
        _header(summary: const Text('الأرقام'), pinned: const Text('بحث')),
      );

      expect(find.text('بحث'), findsOneWidget);
      expect(find.text('الأرقام'), findsNothing);
    });

    testWidgets('a header with only a pinned body has no toggle', (
      tester,
    ) async {
      await _pump(tester, _header(pinned: const Text('بحث')));

      expect(find.text('بحث'), findsOneWidget);
      expect(find.text('الملخص'), findsNothing);
    });

    testWidgets('the collapsed summary stands in for the folded body', (
      tester,
    ) async {
      await _pump(
        tester,
        _header(
          summary: const Text('الأرقام'),
          collapsedSummary: const DashboardSectionSummary(
            items: ['فات موعدها 2'],
          ),
        ),
      );

      expect(find.text('فات موعدها 2'), findsOneWidget);

      await _pressToggle(tester);

      // Opening replaces the stand-in with the real thing rather than showing
      // the same figures twice.
      expect(find.text('الأرقام'), findsOneWidget);
      expect(find.text('فات موعدها 2'), findsNothing);
    });

    testWidgets('the fold is remembered for the session', (tester) async {
      await _pump(
        tester,
        _header(summary: const Text('الأرقام'), sectionId: 'trips.header'),
      );
      await _pressToggle(tester);
      expect(find.text('الأرقام'), findsOneWidget);

      // A fresh mount is what the shell does on every module switch.
      await _pump(tester, const SizedBox.shrink());
      await _pump(
        tester,
        _header(summary: const Text('الأرقام'), sectionId: 'trips.header'),
      );

      expect(find.text('الأرقام'), findsOneWidget);
    });

    testWidgets('without a section id every mount starts folded', (
      tester,
    ) async {
      await _pump(tester, _header(summary: const Text('الأرقام')));
      await _pressToggle(tester);

      await _pump(tester, const SizedBox.shrink());
      await _pump(tester, _header(summary: const Text('الأرقام')));

      expect(find.text('الأرقام'), findsNothing);
    });
  });
}
