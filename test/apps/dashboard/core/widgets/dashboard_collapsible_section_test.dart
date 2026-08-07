import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';

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

Future<void> _tapHeader(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

/// Counts how many times its `build` runs, so a test can prove a collapsed
/// section is not re-running expensive content.
class _BuildCounter extends StatefulWidget {
  const _BuildCounter({required this.label});

  final String label;

  static int builds = 0;
  static int statesCreated = 0;

  @override
  State<_BuildCounter> createState() => _BuildCounterState();
}

class _BuildCounterState extends State<_BuildCounter> {
  @override
  void initState() {
    super.initState();
    _BuildCounter.statesCreated++;
  }

  @override
  Widget build(BuildContext context) {
    _BuildCounter.builds++;
    return Text(widget.label);
  }
}

void main() {
  setUp(() {
    DashboardSectionStateStore.instance.clear();
    _BuildCounter.builds = 0;
    _BuildCounter.statesCreated = 0;
  });

  group('DashboardCollapsibleSection', () {
    testWidgets('starts expanded and folds its content away when tapped', (
      tester,
    ) async {
      await _pump(
        tester,
        const DashboardCollapsibleSection(
          title: 'تحليلات',
          child: Text('المحتوى'),
        ),
      );

      expect(find.text('المحتوى'), findsOneWidget);

      await _tapHeader(tester, 'تحليلات');

      // Offstage keeps the widget in the tree, so `findsOneWidget` would still
      // pass — the assertion has to be that it is not *rendered*.
      expect(find.text('المحتوى', skipOffstage: true), findsNothing);
      expect(find.text('تحليلات'), findsOneWidget, reason: 'header stays');
    });

    testWidgets('tapping again brings the content back', (tester) async {
      await _pump(
        tester,
        const DashboardCollapsibleSection(
          title: 'تحليلات',
          child: Text('المحتوى'),
        ),
      );

      await _tapHeader(tester, 'تحليلات');
      await _tapHeader(tester, 'تحليلات');

      expect(find.text('المحتوى', skipOffstage: true), findsOneWidget);
    });

    testWidgets('honours initiallyExpanded: false', (tester) async {
      await _pump(
        tester,
        const DashboardCollapsibleSection(
          title: 'تحليلات',
          initiallyExpanded: false,
          child: Text('المحتوى'),
        ),
      );

      expect(find.text('المحتوى', skipOffstage: true), findsNothing);
    });

    testWidgets('shows the collapsed summary only while collapsed', (
      tester,
    ) async {
      await _pump(
        tester,
        const DashboardCollapsibleSection(
          title: 'التصفية',
          collapsedSummary: DashboardSectionSummary(items: ['٣ فلاتر مطبقة']),
          child: Text('المحتوى'),
        ),
      );

      expect(find.text('٣ فلاتر مطبقة', skipOffstage: true), findsNothing);

      await _tapHeader(tester, 'التصفية');

      expect(find.text('٣ فلاتر مطبقة', skipOffstage: true), findsOneWidget);
    });

    testWidgets('reports each toggle through onExpansionChanged', (
      tester,
    ) async {
      final events = <bool>[];
      await _pump(
        tester,
        DashboardCollapsibleSection(
          title: 'تحليلات',
          onExpansionChanged: events.add,
          child: const Text('المحتوى'),
        ),
      );

      await _tapHeader(tester, 'تحليلات');
      await _tapHeader(tester, 'تحليلات');

      expect(events, [false, true]);
    });

    testWidgets('header actions do not toggle the section', (tester) async {
      var actionTaps = 0;
      await _pump(
        tester,
        DashboardCollapsibleSection(
          title: 'تحليلات',
          actions: [
            IconButton(
              onPressed: () => actionTaps++,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          child: const Text('المحتوى'),
        ),
      );

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();

      expect(actionTaps, 1);
      expect(
        find.text('المحتوى', skipOffstage: true),
        findsOneWidget,
        reason: 'a refresh button must not fold the panel it sits on',
      );
    });

    testWidgets('exposes an expanded/collapsed state to screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const DashboardCollapsibleSection(
          title: 'تحليلات',
          child: Text('المحتوى'),
        ),
      );

      expect(
        tester.getSemantics(find.text('تحليلات')),
        matchesSemantics(
          label: 'تحليلات',
          isButton: true,
          hasExpandedState: true,
          isExpanded: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      await _tapHeader(tester, 'تحليلات');

      expect(
        tester.getSemantics(find.text('تحليلات')),
        matchesSemantics(
          label: 'تحليلات',
          isButton: true,
          hasExpandedState: true,
          isExpanded: false,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      handle.dispose();
    });
  });

  group('session memory', () {
    testWidgets('a collapsed section is still collapsed after remounting', (
      tester,
    ) async {
      const section = DashboardCollapsibleSection(
        sectionId: 'test.section',
        title: 'تحليلات',
        child: Text('المحتوى'),
      );

      await _pump(tester, section);
      await _tapHeader(tester, 'تحليلات');
      expect(find.text('المحتوى', skipOffstage: true), findsNothing);

      // Standing in for the shell swapping modules and coming back: a brand new
      // element tree, with only the store carrying the operator's choice.
      await _pump(tester, const SizedBox.shrink());
      await _pump(tester, section);

      expect(
        find.text('المحتوى', skipOffstage: true),
        findsNothing,
        reason: 'the collapse must survive leaving and re-entering the module',
      );
    });

    testWidgets('sections keep independent state', (tester) async {
      await _pump(
        tester,
        const Column(
          children: [
            DashboardCollapsibleSection(
              sectionId: 'test.first',
              title: 'الأول',
              child: Text('محتوى الأول'),
            ),
            DashboardCollapsibleSection(
              sectionId: 'test.second',
              title: 'الثاني',
              child: Text('محتوى الثاني'),
            ),
          ],
        ),
      );

      await _tapHeader(tester, 'الأول');

      expect(find.text('محتوى الأول', skipOffstage: true), findsNothing);
      expect(find.text('محتوى الثاني', skipOffstage: true), findsOneWidget);
      expect(DashboardSectionStateStore.instance.debugSnapshot, {
        'test.first': false,
      });
    });

    testWidgets('a remembered state wins over initiallyExpanded', (
      tester,
    ) async {
      DashboardSectionStateStore.instance.setExpanded('test.section', true);

      await _pump(
        tester,
        const DashboardCollapsibleSection(
          sectionId: 'test.section',
          title: 'تحليلات',
          initiallyExpanded: false,
          child: Text('المحتوى'),
        ),
      );

      expect(find.text('المحتوى', skipOffstage: true), findsOneWidget);
    });

    testWidgets('a section without an id remembers nothing', (tester) async {
      const section = DashboardCollapsibleSection(
        title: 'تحليلات',
        child: Text('المحتوى'),
      );

      await _pump(tester, section);
      await _tapHeader(tester, 'تحليلات');
      await _pump(tester, const SizedBox.shrink());
      await _pump(tester, section);

      expect(find.text('المحتوى', skipOffstage: true), findsOneWidget);
      expect(DashboardSectionStateStore.instance.debugSnapshot, isEmpty);
    });

    test('clear() drops every remembered section', () {
      DashboardSectionStateStore.instance
        ..setExpanded('a', false)
        ..setExpanded('b', true);

      DashboardSectionStateStore.instance.clear();

      expect(DashboardSectionStateStore.instance.debugSnapshot, isEmpty);
      expect(
        DashboardSectionStateStore.instance.isExpanded('a', fallback: true),
        isTrue,
        reason: 'a cleared section falls back to its designed default',
      );
    });
  });

  group('cost while collapsed', () {
    testWidgets('a section that starts collapsed never builds its content', (
      tester,
    ) async {
      await _pump(
        tester,
        const DashboardCollapsibleSection(
          title: 'رسم بياني',
          initiallyExpanded: false,
          child: _BuildCounter(label: 'المحتوى'),
        ),
      );

      expect(
        _BuildCounter.statesCreated,
        0,
        reason: 'an unopened chart must cost nothing at all',
      );

      await _tapHeader(tester, 'رسم بياني');

      expect(_BuildCounter.statesCreated, 1);
    });

    testWidgets('collapsing keeps the content alive instead of discarding it', (
      tester,
    ) async {
      await _pump(
        tester,
        const DashboardCollapsibleSection(
          title: 'رسم بياني',
          child: _BuildCounter(label: 'المحتوى'),
        ),
      );
      expect(_BuildCounter.statesCreated, 1);

      await _tapHeader(tester, 'رسم بياني');
      await _tapHeader(tester, 'رسم بياني');

      expect(
        _BuildCounter.statesCreated,
        1,
        reason:
            'reopening must restore the same State — scroll offsets, chart '
            'selections and table pages survive a fold',
      );
    });

    testWidgets('a collapsed section does not rebuild on parent rebuilds', (
      tester,
    ) async {
      final rebuild = ValueNotifier<int>(0);
      addTearDown(rebuild.dispose);

      await _pump(
        tester,
        ValueListenableBuilder<int>(
          valueListenable: rebuild,
          builder: (context, value, _) => DashboardCollapsibleSection(
            title: 'رسم بياني',
            subtitle: 'إصدار $value',
            child: const _BuildCounter(label: 'المحتوى'),
          ),
        ),
      );

      await _tapHeader(tester, 'رسم بياني');
      final buildsWhenCollapsed = _BuildCounter.builds;

      rebuild.value = 1;
      await tester.pumpAndSettle();

      expect(
        _BuildCounter.builds,
        buildsWhenCollapsed,
        reason: 'an offstage chart must not re-run on every parent rebuild',
      );
    });
  });

  group('DashboardPanel', () {
    testWidgets('is not collapsible without a sectionId', (tester) async {
      await _pump(
        tester,
        const DashboardPanel(
          icon: Icons.donut_large_rounded,
          title: 'توزيع الحالات',
          child: Text('المحتوى'),
        ),
      );

      expect(find.byType(DashboardCollapsibleSection), findsNothing);
      expect(find.byIcon(Icons.expand_more_rounded), findsNothing);

      await _tapHeader(tester, 'توزيع الحالات');

      expect(
        find.text('المحتوى', skipOffstage: true),
        findsOneWidget,
        reason: 'panels that opted out must not fold when their title is hit',
      );
    });

    testWidgets('becomes a collapsible section with a sectionId', (
      tester,
    ) async {
      await _pump(
        tester,
        const DashboardPanel(
          sectionId: 'test.panel',
          icon: Icons.donut_large_rounded,
          title: 'توزيع الحالات',
          subtitle: 'كل الرحلات حسب الحالة',
          child: Text('المحتوى'),
        ),
      );

      expect(find.byType(DashboardCollapsibleSection), findsOneWidget);
      expect(find.text('كل الرحلات حسب الحالة'), findsOneWidget);

      await _tapHeader(tester, 'توزيع الحالات');

      expect(find.text('المحتوى', skipOffstage: true), findsNothing);
      expect(DashboardSectionStateStore.instance.debugSnapshot, {
        'test.panel': false,
      });
    });

    testWidgets('keeps its trailing widget reachable as a header action', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        DashboardPanel(
          sectionId: 'test.panel',
          icon: Icons.donut_large_rounded,
          title: 'توزيع الحالات',
          trailing: TextButton(
            onPressed: () => taps++,
            child: const Text('عرض الكل'),
          ),
          child: const Text('المحتوى'),
        ),
      );

      await tester.tap(find.text('عرض الكل'));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(find.text('المحتوى', skipOffstage: true), findsOneWidget);
    });
  });
}
