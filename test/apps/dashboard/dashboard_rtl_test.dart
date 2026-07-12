import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/domain/entities/notification_draft.dart';
import 'package:bmt_app/core/widgets/progress_bar.dart';

Widget _rtl(Widget child) => MaterialApp(
  home: Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(body: child),
  ),
);

Icon _iconAt(WidgetTester tester, String tooltip) => tester.widget<Icon>(
  find.descendant(of: find.byTooltip(tooltip), matching: find.byType(Icon)),
);

void main() {
  group('directional icons mirror instead of being hand-flipped', () {
    // The dashboard renders RTL, and Material's directional icons carry
    // matchTextDirection: true — they mirror themselves. So the source must
    // name the LTR-semantic icon (next = chevron_right) and let the framework
    // flip it; naming the already-flipped icon renders it backwards.
    testWidgets('pagination uses LTR-semantic icons that mirror under RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _rtl(
          OpsDataTable(
            columns: const [OpsColumn('الاسم')],
            rows: const [
              [Text('أحمد')],
            ],
            total: 16,
            currentPage: 1,
            pageSize: 8,
            onPageChanged: (_) {},
          ),
        ),
      );

      final prev = _iconAt(tester, 'السابق');
      final next = _iconAt(tester, 'التالي');

      expect(prev.icon, Icons.chevron_left_rounded);
      expect(next.icon, Icons.chevron_right_rounded);

      // Both must be self-mirroring, otherwise they would point the wrong way.
      expect(prev.icon!.matchTextDirection, isTrue);
      expect(next.icon!.matchTextDirection, isTrue);
    });

    testWidgets('previous sits to the right of next in an RTL row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _rtl(
          OpsDataTable(
            columns: const [OpsColumn('الاسم')],
            rows: const [
              [Text('أحمد')],
            ],
            total: 16,
            currentPage: 1,
            pageSize: 8,
            onPageChanged: (_) {},
          ),
        ),
      );

      final prevX = tester.getCenter(find.byTooltip('السابق')).dx;
      final nextX = tester.getCenter(find.byTooltip('التالي')).dx;
      expect(prevX, greaterThan(nextX));
    });
  });

  testWidgets('progress bar fills from the right under RTL', (tester) async {
    await tester.pumpWidget(
      _rtl(
        const Center(
          child: SizedBox(width: 200, child: AppProgressBar(progress: 0.5)),
        ),
      ),
    );

    final track = tester.getRect(find.byType(AppProgressBar));
    final fill = tester.getRect(
      find.descendant(
        of: find.byType(FractionallySizedBox),
        matching: find.byType(DecoratedBox),
      ),
    );

    expect(fill.width, closeTo(track.width / 2, 0.5));
    // Anchored to the start edge, which is the right edge in RTL.
    expect(fill.right, closeTo(track.right, 0.5));
    expect(fill.left, greaterThan(track.left));
  });

  test('notification labels shown to operators are Arabic', () {
    for (final category in DashboardNotificationCategory.values) {
      expect(
        category.label,
        matches(RegExp(r'[؀-ۿ]')),
        reason: '${category.name} must have an Arabic label',
      );
    }
    for (final target in NotificationTargetApp.values) {
      expect(
        target.label,
        matches(RegExp(r'[؀-ۿ]')),
        reason: '${target.name} must have an Arabic label',
      );
    }
  });

  test('dashboard never forces LTR', () {
    // Latin-only values (a phone number) are legitimately pinned LTR so their
    // digits are not reordered; everything else must inherit the app's RTL.
    const allowed = {
      'lib/apps/dashboard/features/captain_requests/presentation/widgets/captain_request_card.dart',
    };

    final offenders = <String>[];
    for (final entity in Directory('lib/apps/dashboard').listSync(
      recursive: true,
    )) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (allowed.contains(path)) continue;
      if (entity.readAsStringSync().contains('TextDirection.ltr')) {
        offenders.add(path);
      }
    }

    expect(offenders, isEmpty);
  });
}
