import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/captain_day_summary.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/presentation/widgets/assigned_trip_card.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/presentation/widgets/assigned_trips_section_title.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/presentation/widgets/assigned_trips_stats_strip.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/presentation/widgets/captain_day_complete_view.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/presentation/widgets/captain_focus_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scale in [1.0, 1.3]) {
    testWidgets('home widgets render without overflow @ textScale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final trips = [
        _trip('a', 8, status: AssignedTripStatus.inProgress, boarded: 12),
        _trip('b', 13),
        _trip('c', 18, status: AssignedTripStatus.completed, boarded: 20),
      ];
      final summary = CaptainDaySummary.fromTrips(trips);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    CaptainFocusCard(trip: summary.focusTrip!, onOpen: () {}),
                    const SizedBox(height: 16),
                    AssignedTripsStatsStrip(summary: summary),
                    const SizedBox(height: 24),
                    const AssignedTripsSectionTitle(
                      title: 'بقية رحلات اليوم',
                      count: 2,
                    ),
                    const SizedBox(height: 12),
                    for (final trip in trips.skip(1))
                      AssignedTripCard(
                        trip: trip,
                        onOpen: () {},
                        onManifest: () {},
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('متابعة الرحلة'), findsOneWidget);
      expect(find.text('رحلتك الحالية'), findsOneWidget);

      // The completed trip sits below the fold at larger text scales, so it
      // has to be scrolled to rather than assumed built — and scrolling also
      // puts the lower cards through the same overflow check as the hero.
      await tester.scrollUntilVisible(find.text('كشف الركاب'), 200);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Completed trips offer the manifest, never a "start the trip" action.
      expect(find.text('كشف الركاب'), findsOneWidget);
    });

    testWidgets('finished day renders without overflow @ textScale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final summary = CaptainDaySummary.fromTrips([
        _trip('a', 8, status: AssignedTripStatus.completed, boarded: 18),
        _trip('b', 13, status: AssignedTripStatus.completed, boarded: 20),
        _trip('c', 18, status: AssignedTripStatus.completed, boarded: 16),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    CaptainDayCompleteView(
                      summary: summary,
                      onRefresh: () async {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('أحسنت، أنهيت رحلات اليوم'), findsOneWidget);
      // The day's numbers: three trips, 54 passengers carried, and the last
      // trip departs at 18:00 and runs three hours.
      expect(find.text('3'), findsOneWidget);
      expect(find.text('54'), findsOneWidget);
      expect(find.text('21:00'), findsOneWidget);
      // The captain is told where the next trip comes from, and can ask now.
      expect(find.text('بانتظار رحلتك التالية'), findsOneWidget);
      expect(find.text('تحديث الآن'), findsOneWidget);
    });
  }

  group('the day-list card', () {
    testWidgets('states how long the trip runs and how many stations it makes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // Both facts were already on the entity and neither reached the card: a
      // captain could not tell a two-stop hop from a nine-stop run, or see how
      // long either kept them out, without opening the trip.
      await tester.pumpWidget(
        _host(
          AssignedTripCard(
            trip: _trip('a', 8, stops: _stops),
            onOpen: () {},
            onManifest: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3س 0د'), findsOneWidget);
      expect(find.text('3 محطات'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens the trip from anywhere on it, not only its button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      var opened = 0;
      await tester.pumpWidget(
        _host(
          AssignedTripCard(
            trip: _trip('a', 8),
            onOpen: () => opened++,
            onManifest: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The route name is card body, not a control — it used to be dead space.
      await tester.tap(find.text('محطة مصر - سيدي جابر'));
      await tester.pump();

      expect(opened, 1);
    });
  });
}

AssignedTrip _trip(
  String id,
  int hour, {
  AssignedTripStatus status = AssignedTripStatus.scheduled,
  int boarded = 0,
  List<AssignedTripStop> stops = const [],
}) {
  final departure = DateTime(2026, 7, 14, hour);
  return AssignedTrip(
    id: id,
    route: 'محطة مصر - سيدي جابر',
    vehicleNumber: 'BUS-$id',
    plateNumber: 'أ ب ج 123',
    departureTime: departure,
    expectedArrivalTime: departure.add(const Duration(hours: 3)),
    stops: stops,
    passengerCount: 20,
    boardedCount: boarded,
    status: status,
  );
}

const _stops = [
  AssignedTripStop(id: 's1', name: 'موقف عبود'),
  AssignedTripStop(id: 's2', name: 'محطة مسطرد'),
  AssignedTripStop(id: 's3', name: 'موقف المنشية'),
];

Widget _host(Widget child) {
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: ListView(padding: const EdgeInsets.all(20), children: [child]),
      ),
    ),
  );
}
