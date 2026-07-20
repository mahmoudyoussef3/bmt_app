import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_labels.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_ticker.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/presentation/widgets/captain_focus_card.dart';

void main() {
  group(
    'the focus card states the scheduled departure, not only a countdown',
    () {
      testWidgets('shows the departure clock for every stage', (tester) async {
        final departure = DateTime.now().add(const Duration(hours: 4));

        await tester.pumpWidget(
          _host(_trip(departure, AssignedTripStatus.openForBooking)),
        );

        // The absolute time is the captain's cross-check against the trip's own
        // schedule — a relative countdown alone gave them nothing to verify a
        // suspicious "in two minutes" against.
        final hour = departure.hour.toString().padLeft(2, '0');
        final minute = departure.minute.toString().padLeft(2, '0');
        expect(find.textContaining('$hour:$minute'), findsWidgets);
      });

      testWidgets(
        'an unreleased trip says it is waiting on operations and does '
        'not offer to start',
        (tester) async {
          final departure = DateTime.now().add(const Duration(minutes: 5));

          await tester.pumpWidget(
            _host(_trip(departure, AssignedTripStatus.scheduled)),
          );

          expect(
            find.text('بانتظار فتح الحجز من إدارة العمليات'),
            findsOneWidget,
          );
          expect(find.text('بدء الرحلة'), findsNothing);
          expect(find.text('بدء صعود الركاب'), findsNothing);
        },
      );

      testWidgets('a published trip inside the window offers boarding', (
        tester,
      ) async {
        final departure = DateTime.now().add(const Duration(minutes: 5));

        await tester.pumpWidget(
          _host(_trip(departure, AssignedTripStatus.openForBooking)),
        );

        expect(find.text('بدء صعود الركاب'), findsOneWidget);
      });
    },
  );

  group('CaptainTicker', () {
    testWidgets('rebuilds on the wall clock, so a countdown cannot freeze at '
        'the value it had when the screen loaded', (tester) async {
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: CaptainTicker(
            interval: const Duration(seconds: 1),
            builder: (context, now) {
              builds++;
              return Text('$now');
            },
          ),
        ),
      );

      expect(builds, 1);

      // No state change, no new data — only time passing.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(builds, 3);
    });
  });

  group('CaptainTripStageLabels.status', () {
    test('counts down to the moment boarding opens, not to departure', () {
      final departure = DateTime(2026, 7, 20, 14);
      // 90 minutes before departure = 60 minutes before boarding opens.
      final now = departure.subtract(const Duration(minutes: 90));

      final label = CaptainTripStageLabels.status(
        stage: CaptainTripStage.awaitingWindow,
        departureTime: departure,
        now: now,
      );

      expect(label, contains('13:30'));
      expect(label, contains('بعد 1 ساعة'));
    });

    test('reports a late departure as overdue rather than as a countdown', () {
      final departure = DateTime(2026, 7, 20, 14);

      final label = CaptainTripStageLabels.status(
        stage: CaptainTripStage.boarding,
        departureTime: departure,
        now: departure.add(const Duration(minutes: 12)),
      );

      expect(label, contains('تأخر الانطلاق'));
      expect(label, contains('12 دقيقة'));
    });
  });
}

Widget _host(AssignedTrip trip) {
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SingleChildScrollView(
          child: CaptainFocusCard(trip: trip, onOpen: () {}),
        ),
      ),
    ),
  );
}

AssignedTrip _trip(DateTime departure, AssignedTripStatus status) {
  return AssignedTrip(
    id: 'trip-1',
    route: 'القاهرة - الإسكندرية',
    vehicleNumber: 'BUS-1',
    plateNumber: 'أ ب ج 123',
    departureTime: departure,
    expectedArrivalTime: departure.add(const Duration(hours: 3)),
    stops: const [],
    passengerCount: 20,
    boardedCount: 3,
    status: status,
  );
}
