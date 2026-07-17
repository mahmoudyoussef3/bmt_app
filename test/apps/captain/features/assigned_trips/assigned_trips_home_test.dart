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
}

AssignedTrip _trip(
  String id,
  int hour, {
  AssignedTripStatus status = AssignedTripStatus.scheduled,
  int boarded = 0,
}) {
  final departure = DateTime(2026, 7, 14, hour);
  return AssignedTrip(
    id: id,
    route: 'محطة مصر - سيدي جابر',
    vehicleNumber: 'BUS-$id',
    plateNumber: 'أ ب ج 123',
    departureTime: departure,
    expectedArrivalTime: departure.add(const Duration(hours: 3)),
    stops: const [],
    passengerCount: 20,
    boardedCount: boarded,
    status: status,
  );
}
