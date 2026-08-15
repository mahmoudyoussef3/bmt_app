import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
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

  group('directional glyphs live in one file', () {
    // The mirroring rule above is one sentence long and was still broken at
    // eight call sites — a "back" button drawn with a forward arrow in
    // routes, a "متابعة" button pointing backwards in the wallet, two
    // "عرض التفاصيل" actions in bookings and trips pointing opposite ways,
    // and bookings' pagination inverted against every other pager.
    //
    // Restating the rule in a comment would not have caught any of them. What
    // catches them is removing the choice: call sites name an intent
    // (DashboardIcons.back / .forward / .paginationPrevious / …) and only
    // this one file is allowed to know which glyph that is.
    test('no dashboard file names a raw directional glyph', () {
      const directional = [
        'Icons.chevron_left',
        'Icons.chevron_right',
        'Icons.arrow_back',
        'Icons.arrow_forward',
        'Icons.keyboard_arrow_left',
        'Icons.keyboard_arrow_right',
        'Icons.navigate_before',
        'Icons.navigate_next',
      ];
      const vocabulary = 'lib/apps/dashboard/core/theme/dashboard_icons.dart';

      final offenders = <String>[];
      for (final entity in Directory(
        'lib/apps/dashboard',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path.replaceAll(r'\', '/');
        if (path == vocabulary) continue;
        final source = entity.readAsStringSync();
        for (final glyph in directional) {
          if (source.contains(glyph)) offenders.add('$path → $glyph');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Directional icons self-mirror under RTL. Name the intent from '
            'DashboardIcons instead of the glyph.',
      );
    });

    test('every directional token is self-mirroring and LTR-semantic', () {
      // If one of these were swapped to its already-flipped twin it would
      // render backwards everywhere at once — which is the trade this
      // centralisation makes, so it is worth one assertion.
      expect(DashboardIcons.back, Icons.arrow_back_rounded);
      expect(DashboardIcons.forward, Icons.arrow_forward_rounded);
      expect(DashboardIcons.paginationPrevious, Icons.chevron_left_rounded);
      expect(DashboardIcons.paginationNext, Icons.chevron_right_rounded);
      expect(DashboardIcons.openModule, Icons.chevron_right_rounded);

      for (final icon in [
        DashboardIcons.back,
        DashboardIcons.forward,
        DashboardIcons.paginationPrevious,
        DashboardIcons.paginationNext,
        DashboardIcons.openModule,
        DashboardIcons.breadcrumbSeparator,
        DashboardIcons.transition,
      ]) {
        expect(icon.matchTextDirection, isTrue);
      }
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
    // Chrome, text and navigation must inherit the app's RTL. Two things
    // legitimately do not, and both are exempted by name rather than by pattern
    // so a third one cannot appear without someone deciding it should:
    //
    //  1. A Latin-only value (a phone number), pinned so its digits are not
    //     reordered around the surrounding Arabic.
    //  2. The vehicle cabin grids — Fleet's layout preview and the trip seats
    //     tab. A seat map is a picture of a physical object, not a line of
    //     text: column 1 of a blueprint is the driver's side of a left-hand-
    //     drive bus, and mirroring it for Arabic would move the steering wheel
    //     to the right and every window seat to the opposite wall. The Arabic
    //     labels around the grid still flow RTL.
    const allowed = {
      'lib/apps/dashboard/features/captain_requests/presentation/widgets/captain_request_card.dart',
      'lib/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_seat_layout_visualizer.dart',
      'lib/apps/dashboard/features/trips/presentation/widgets/trip_seat_map.dart',
    };

    final offenders = <String>[];
    for (final entity in Directory(
      'lib/apps/dashboard',
    ).listSync(recursive: true)) {
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
