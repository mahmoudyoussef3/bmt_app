import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/entities/trip_execution_state.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/widgets/trip_gps_status_card.dart';

void main() {
  const destination = AssignedTripStop(
    id: 'stop-1',
    name: 'محطة الوصول',
    // Roughly 1.11 km north of the fix below (0.01 degrees latitude).
    latitude: 30.10,
    longitude: 31.20,
  );
  // A fix ~1.11 km from the destination — only the coordinates matter for
  // the freshness tests below; each supplies its own recordedAt.
  const nearLat = 30.09;
  const nearLng = 31.20;

  Future<void> pump(
    WidgetTester tester, {
    required TripLastLocationFix? lastLocation,
    required AssignedTripStop? destination,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: TripGpsStatusCard(
              lastLocation: lastLocation,
              destination: destination,
              expectedArrivalTime: DateTime(2026, 7, 16, 14, 30),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows "no location sent" when nothing has been sent yet', (
    tester,
  ) async {
    await pump(tester, lastLocation: null, destination: destination);

    expect(find.text('لم يُرسل أي موقع لهذه الرحلة بعد'), findsOneWidget);
    expect(find.text('—'), findsOneWidget); // distance remaining
  });

  testWidgets('formats sub-kilometer distances in meters', (tester) async {
    final fix = TripLastLocationFix(
      latitude: destination.latitude!,
      longitude: destination.longitude! - 0.001, // ~96 m away
      recordedAt: DateTime.now(),
    );

    await pump(tester, lastLocation: fix, destination: destination);

    expect(_textMatching(RegExp(r'^\d+ م$')), findsOneWidget);
  });

  testWidgets('formats kilometer-scale distances in km', (tester) async {
    final fix = TripLastLocationFix(
      latitude: 30.09,
      longitude: 31.20,
      recordedAt: DateTime.now(),
    );

    await pump(tester, lastLocation: fix, destination: destination);

    expect(_textMatching(RegExp(r'^\d+\.\d+ كم$')), findsOneWidget);
  });

  testWidgets(
    'shows "—" for distance when the destination has no coordinates',
    (tester) async {
      const noCoordsDestination = AssignedTripStop(id: 'x', name: 'محطة');
      final fix = TripLastLocationFix(
        latitude: 30.09,
        longitude: 31.20,
        recordedAt: DateTime.now(),
      );

      await pump(tester, lastLocation: fix, destination: noCoordsDestination);

      expect(find.text('—'), findsOneWidget);
    },
  );

  // Freshness thresholds are calibrated to the one-minute automatic reporting
  // interval: a running trip should never be more than a minute or two behind,
  // so a fix older than that means the sends themselves are failing.
  testWidgets('a fix from the last minute reads as up to date', (tester) async {
    final fix = TripLastLocationFix(
      latitude: nearLat,
      longitude: nearLng,
      recordedAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    await pump(tester, lastLocation: fix, destination: destination);

    expect(find.textContaining('محدّث'), findsOneWidget);
  });

  testWidgets('a 5-minute-old fix reads as possibly stale — several '
      'automatic sends have been missed', (tester) async {
    final fix = TripLastLocationFix(
      latitude: nearLat,
      longitude: nearLng,
      recordedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    await pump(tester, lastLocation: fix, destination: destination);

    expect(find.textContaining('قد يكون قديماً'), findsOneWidget);
  });

  testWidgets('a 20-minute-old fix reads as stale', (tester) async {
    final fix = TripLastLocationFix(
      latitude: nearLat,
      longitude: nearLng,
      recordedAt: DateTime.now().subtract(const Duration(minutes: 20)),
    );

    await pump(tester, lastLocation: fix, destination: destination);

    expect(find.textContaining('قديم —'), findsOneWidget);
  });
}

Finder _textMatching(RegExp pattern) {
  return find.byWidgetPredicate(
    (widget) => widget is Text && pattern.hasMatch(widget.data ?? ''),
  );
}
