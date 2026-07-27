import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/live_ops_snapshot.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/trip_incident.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/widgets/departure_status_badge.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/widgets/incident_queue_section.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/widgets/live_ops_summary_bar.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/widgets/live_trip_card.dart';

/// Widths the dashboard is actually used at: a narrow drawer-mode window, a
/// tablet split, and a wide desktop workspace. The incident panel is the
/// narrowest column on screen, so 320 stands in for it.
const _widths = <double>[320, 360, 720, 1024, 1440];

/// Text scales a real operator may run: default, the OS "large" step, and the
/// accessibility maximum this dashboard supports.
const _textScales = <double>[1.0, 1.3, 1.6];

final _now = DateTime(2026, 7, 27, 9);

LiveTrip _trip({
  String id = 't1',
  bool inProgress = false,
  DateTime? scheduledDeparture,
  DateTime? actualStart,
  LiveFix? fix,
}) => LiveTrip(
  id: id,
  statusLabel: inProgress ? 'جارية' : 'صعود الركاب',
  isInProgress: inProgress,
  routeName: 'المنصورة - القاهرة عبر طريق بنها السريع',
  driverName: 'أحمد محمد عبد الرحمن السيد',
  driverPhone: '01001234567',
  vehicleLabel: 'ط ر ق ١٢٣٤',
  tripDate: '2026-07-27',
  departureTime: '08:00',
  capacity: 14,
  bookedSeats: 11,
  lastFix: fix,
  scheduledDeparture: scheduledDeparture,
  actualStart: actualStart,
);

TripIncident _incident({
  String id = 'i1',
  IncidentType type = IncidentType.emergency,
  IncidentStatus status = IncidentStatus.pending,
}) => TripIncident(
  id: id,
  tripId: 't1',
  type: type,
  description:
      'عطل مفاجئ في المكابح أثناء السير على الطريق السريع ويتطلب مركبة بديلة فوراً.',
  status: status,
  createdAt: _now.subtract(const Duration(minutes: 12)),
  routeName: 'المنصورة - القاهرة عبر طريق بنها السريع',
  driverName: 'أحمد محمد عبد الرحمن السيد',
  vehicleLabel: 'ط ر ق ١٢٣٤',
);

/// Renders [child] at [width] and [textScale] inside the real dashboard theme
/// and RTL, then fails if layout overflowed.
///
/// An overflowing `Row`/`Column` throws during paint in debug builds and the
/// binding captures it, so a null `takeException()` is a genuine assertion.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required double width,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: DashboardAppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _expectNoOverflow(
  WidgetTester tester,
  Widget child, {
  required double width,
  double textScale = 1.0,
}) async {
  await _pump(tester, child, width: width, textScale: textScale);
  expect(
    tester.takeException(),
    isNull,
    reason: 'layout overflowed at ${width}px @ ${textScale}x text',
  );
}

void main() {
  group('DepartureStatusBadge', () {
    testWidgets('an overdue boarding trip names its delay', (tester) async {
      await _pump(
        tester,
        DepartureStatusBadge(
          trip: _trip(
            scheduledDeparture: _now.subtract(const Duration(minutes: 35)),
          ),
          now: _now,
        ),
        width: 400,
      );
      expect(find.textContaining('تأخّر الانطلاق'), findsOneWidget);
      expect(find.textContaining('35 د'), findsOneWidget);
    });

    testWidgets('an hour-plus delay reads hours and minutes', (tester) async {
      await _pump(
        tester,
        DepartureStatusBadge(
          trip: _trip(
            scheduledDeparture: _now.subtract(
              const Duration(hours: 1, minutes: 50),
            ),
          ),
          now: _now,
        ),
        width: 400,
      );
      expect(find.textContaining('1 س و50 د'), findsOneWidget);
    });

    testWidgets('a trip not yet due renders nothing at all', (tester) async {
      await _pump(
        tester,
        DepartureStatusBadge(
          trip: _trip(
            scheduledDeparture: _now.add(const Duration(minutes: 30)),
          ),
          now: _now,
        ),
        width: 400,
      );
      // No reassuring badge nobody needs.
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('an unknown schedule renders nothing rather than guessing', (
      tester,
    ) async {
      await _pump(
        tester,
        DepartureStatusBadge(trip: _trip(), now: _now),
        width: 400,
      );
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('a departed trip reports the lateness it actually had', (
      tester,
    ) async {
      await _pump(
        tester,
        DepartureStatusBadge(
          trip: _trip(
            inProgress: true,
            scheduledDeparture: _now.subtract(const Duration(hours: 2)),
            actualStart: _now.subtract(const Duration(minutes: 85)),
          ),
          now: _now,
        ),
        width: 400,
      );
      expect(find.textContaining('انطلقت متأخرة'), findsOneWidget);
    });
  });

  group('IncidentQueueSection offers only legal transitions', () {
    testWidgets('a new report can be claimed, closed or dismissed', (
      tester,
    ) async {
      await _pump(
        tester,
        IncidentQueueSection(
          incidents: [_incident()],
          now: _now,
          onAction: (_, _, {note}) async => null,
        ),
        width: 500,
      );
      expect(find.text('استلام'), findsOneWidget);
      expect(find.text('تم الحل'), findsOneWidget);
      expect(find.text('استبعاد'), findsOneWidget);
      expect(find.text('جديد'), findsOneWidget);
    });

    testWidgets('an owned report can no longer be claimed again', (
      tester,
    ) async {
      await _pump(
        tester,
        IncidentQueueSection(
          incidents: [_incident(status: IncidentStatus.acknowledged)],
          now: _now,
          onAction: (_, _, {note}) async => null,
        ),
        width: 500,
      );
      // Re-acknowledging would erase who took ownership, so it is not offered.
      expect(find.text('استلام'), findsNothing);
      expect(find.text('تم الحل'), findsOneWidget);
      expect(find.text('قيد المعالجة'), findsOneWidget);
    });

    testWidgets('claiming a report fires the acknowledge transition', (
      tester,
    ) async {
      IncidentStatus? requested;
      await _pump(
        tester,
        IncidentQueueSection(
          incidents: [_incident()],
          now: _now,
          onAction: (incident, next, {note}) async {
            requested = next;
            return null;
          },
        ),
        width: 500,
      );

      await tester.tap(find.text('استلام'));
      await tester.pumpAndSettle();

      expect(requested, IncidentStatus.acknowledged);
    });

    testWidgets('closing requires a note before it will submit', (
      tester,
    ) async {
      var submitted = false;
      await _pump(
        tester,
        IncidentQueueSection(
          incidents: [_incident()],
          now: _now,
          onAction: (_, _, {note}) async {
            submitted = true;
            return null;
          },
        ),
        width: 500,
      );

      await tester.tap(find.text('تم الحل'));
      await tester.pumpAndSettle();

      // Submitting an empty note is refused: a closed incident with no account
      // of the fix is indistinguishable from a mis-click.
      await tester.tap(find.widgetWithText(FilledButton, 'تم الحل'));
      await tester.pumpAndSettle();
      expect(submitted, isFalse);
      expect(find.textContaining('لا يقل عن'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField),
        'تم إرسال مركبة بديلة ونقل الركاب',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'تم الحل'));
      await tester.pumpAndSettle();
      expect(submitted, isTrue);
    });
  });

  group('Incident actions respect the operator permission', () {
    testWidgets('a read-only viewer sees the queue but no action buttons', (
      tester,
    ) async {
      await _pump(
        tester,
        IncidentQueueSection(
          incidents: [_incident()],
          now: _now,
          canAct: false,
          onAction: (_, _, {note}) async => null,
        ),
        width: 500,
      );

      // The report itself is fully visible — that is why support agents have
      // the module at all.
      expect(find.text('طوارئ / نجدة'), findsOneWidget);
      expect(find.text('جديد'), findsOneWidget);
      // But no disabled button invites them to keep clicking.
      expect(find.text('استلام'), findsNothing);
      expect(find.text('تم الحل'), findsNothing);
      expect(find.text('استبعاد'), findsNothing);
    });
  });

  group('Live Ops layout survives every width and text scale', () {
    final snapshot = LiveOpsSnapshot(
      generatedAt: _now,
      activeTrips: [
        _trip(
          id: 'a',
          scheduledDeparture: _now.subtract(const Duration(minutes: 45)),
        ),
        _trip(id: 'b', inProgress: true),
      ],
      incidents: [
        _incident(),
        _incident(id: 'i2', type: IncidentType.delay),
      ],
    );

    for (final width in _widths) {
      for (final scale in _textScales) {
        testWidgets('summary bar @ ${width}px ${scale}x', (tester) async {
          await _expectNoOverflow(
            tester,
            LiveOpsSummaryBar(snapshot: snapshot, now: _now),
            width: width,
            textScale: scale,
          );
        });

        testWidgets('overdue trip card @ ${width}px ${scale}x', (tester) async {
          await _expectNoOverflow(
            tester,
            LiveTripCard(
              trip: _trip(
                scheduledDeparture: _now.subtract(
                  const Duration(hours: 2, minutes: 13),
                ),
              ),
              now: _now,
              selected: true,
              onTap: () {},
            ),
            width: width,
            textScale: scale,
          );
        });

        testWidgets('incident queue @ ${width}px ${scale}x', (tester) async {
          await _expectNoOverflow(
            tester,
            IncidentQueueSection(
              incidents: [
                _incident(),
                _incident(id: 'i2', status: IncidentStatus.acknowledged),
              ],
              now: _now,
              onAction: (_, _, {note}) async => null,
            ),
            width: width,
            textScale: scale,
          );
        });
      }
    }
  });

  group('RTL correctness', () {
    testWidgets('trip card content starts at the right edge in RTL', (
      tester,
    ) async {
      await _pump(
        tester,
        LiveTripCard(trip: _trip(), now: _now, onTap: () {}),
        width: 500,
      );

      final route = tester.getRect(
        find.text('المنصورة - القاهرة عبر طريق بنها السريع'),
      );
      final health = tester.getRect(find.text('غير معروفة'));
      // In RTL the route title leads (right) and the health badge trails (left).
      expect(
        route.right,
        greaterThan(health.right),
        reason: 'route title must lead on the right in RTL',
      );
    });
  });
}
