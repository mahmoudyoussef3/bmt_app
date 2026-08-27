import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_stop_timeline.dart';

import '../../client_test_app.dart';

/// A station's clocks are *derived*: it stores an `"HH:MM"` offset from the
/// line's start, and the hour a rider reads is a trip's departure plus that
/// offset. These lock the rules that decide which of the two clocks each
/// station is allowed to print.
void main() {
  Future<void> pumpTimeline(
    WidgetTester tester, {
    required List<RoutePointData> points,
    String referenceDeparture = '07:30:00',
  }) async {
    await tester.pumpWidget(
      clientTestApp(
        Scaffold(
          body: SingleChildScrollView(
            child: RouteStopTimeline(
              points: points,
              referenceDeparture: referenceDeparture,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  RoutePointData stop(
    String name,
    int order, {
    String arrival = '',
    String departure = '',
    double? lat,
    double? lng,
  }) {
    return RoutePointData(
      name: name,
      order: order,
      arrivalOffset: arrival,
      departureOffset: departure,
      latitude: lat,
      longitude: lng,
    );
  }

  final corridor = [
    stop('Origin', 1, arrival: '00:00', departure: '00:00'),
    stop('Waited at', 2, arrival: '00:22', departure: '00:25'),
    stop('Passed through', 3, arrival: '00:41', departure: '00:41'),
    stop('Destination', 4, arrival: '01:06', departure: '01:06'),
  ];

  testWidgets('the origin prints its departure, not its arrival', (
    tester,
  ) async {
    await pumpTimeline(tester, points: corridor);

    expect(find.text('Departs 7:30 AM'), findsOneWidget);
    expect(find.text('Arrives 7:30 AM'), findsNothing);
  });

  testWidgets('a station the bus waits at prints both clocks', (tester) async {
    await pumpTimeline(tester, points: corridor);

    expect(find.text('Arrives 7:52 AM'), findsOneWidget);
    expect(find.text('Departs 7:55 AM'), findsOneWidget);
  });

  testWidgets('a station with no dwell prints one clock, not the same twice', (
    tester,
  ) async {
    await pumpTimeline(tester, points: corridor);

    expect(find.text('Arrives 8:11 AM'), findsOneWidget);
    expect(find.text('Departs 8:11 AM'), findsNothing);
  });

  testWidgets('the destination prints its arrival, not a departure', (
    tester,
  ) async {
    await pumpTimeline(tester, points: corridor);

    expect(find.text('Arrives 8:36 AM'), findsOneWidget);
    expect(find.text('Departs 8:36 AM'), findsNothing);
  });

  testWidgets('without a departure clock, stations fall back to the offset', (
    tester,
  ) async {
    await pumpTimeline(tester, points: corridor, referenceDeparture: '');

    expect(find.text('Arrives 22m after departure'), findsOneWidget);
    expect(find.textContaining('AM'), findsNothing);
  });

  testWidgets('an untimed station is shown without a time', (tester) async {
    await pumpTimeline(
      tester,
      points: [stop('Origin', 1), stop('Destination', 2)],
    );

    expect(find.textContaining('Arrives'), findsNothing);
    expect(find.textContaining('Departs'), findsNothing);
    // ...and with nothing to explain, the estimate note stays away too.
    expect(find.textContaining('Estimated times'), findsNothing);
  });

  testWidgets('only a mapped station offers to open in a maps app', (
    tester,
  ) async {
    await pumpTimeline(
      tester,
      points: [
        stop(
          'Mapped',
          1,
          arrival: '00:00',
          departure: '00:00',
          lat: 30.02,
          lng: 31.49,
        ),
        stop('Unmapped', 2, arrival: '00:22', departure: '00:22'),
      ],
    );

    expect(find.text('Open in maps'), findsOneWidget);
  });
}
