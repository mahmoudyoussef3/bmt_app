import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_stations_card.dart';
import '../../client_test_app.dart';

/// The stops section answers the question the hero cannot: a rider who boards
/// mid-corridor needs the whole road, not the ticket's two place names.

List<TripStop> _corridor({int count = 4, int boarding = 1, int dropoff = 2}) {
  const names = [
    'Cairo',
    'Banha',
    'Tanta',
    'Mahalla',
    'Samannoud',
    'Mansoura',
    'Dekernes',
    'Aga',
  ];

  return [
    for (var i = 0; i < count; i++)
      TripStop(
        id: 'p$i',
        stationId: 's$i',
        name: names[i],
        order: i,
        // One hour between stops, measured from the route's start.
        arrivalOffset: '0$i:00',
        departureOffset: '0$i:05',
        isBoarding: i == boarding,
        isDropoff: i == dropoff,
      ),
  ];
}

TripData _trip({List<TripStop> stops = const []}) {
  return TripData(
    id: 'b1',
    reference: 'BMT-TEST',
    status: TripStatus.upcoming,
    pickup: 'Cairo',
    destination: 'Mansoura',
    dateLabel: '2030-01-15',
    timeLabel: '08:00:00',
    driverName: 'Sam',
    driverPhone: '',
    driverInitials: 'SA',
    driverRating: 4.8,
    vehicleName: 'Coaster',
    vehicleType: 'Minibus',
    vehicleId: 'v1',
    seats: const ['1'],
    paymentStatus: PaymentStatus.paid,
    fare: 'EGP 50',
    stops: stops,
  );
}

Future<void> _pump(WidgetTester tester, TripData trip) async {
  await tester.binding.setSurfaceSize(const Size(430, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    clientTestApp(
      Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TripStationsCard(trip: trip),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a trip with no stops on file draws no section at all', (
    tester,
  ) async {
    await _pump(tester, _trip());

    expect(find.text('Trip stops'), findsNothing);
  });

  testWidgets('every stop is named, in running order', (tester) async {
    await _pump(tester, _trip(stops: _corridor()));

    expect(find.text('Trip stops'), findsOneWidget);
    for (final name in ['Cairo', 'Banha', 'Tanta', 'Mahalla']) {
      expect(find.text(name), findsWidgets);
    }
  });

  testWidgets("the rider's own two stops are the badged ones", (tester) async {
    await _pump(tester, _trip(stops: _corridor()));

    expect(find.text('Your stop'), findsOneWidget);
    expect(find.text('Your drop-off'), findsOneWidget);
  });

  testWidgets('a stop is clocked from the departure plus its offset, never '
      'from the raw offset', (tester) async {
    await _pump(tester, _trip(stops: _corridor()));

    // Departure 08:00, and the third stop sits two hours down the corridor.
    expect(find.text('8:00 AM'), findsWidgets);
    expect(find.text('10:00 AM'), findsWidgets);
    expect(find.text('02:00'), findsNothing);
  });

  testWidgets('a long corridor collapses to the leg the rider rides, and says '
      'how many it is hiding', (tester) async {
    await _pump(
      tester,
      _trip(stops: _corridor(count: 8, boarding: 3, dropoff: 5)),
    );

    // Boarding is stop 4 of 8, so the far terminals are out of the window.
    expect(find.text('Cairo'), findsNothing);
    expect(find.text('Mahalla'), findsWidgets);
    expect(find.text('Show all 8 stops'), findsOneWidget);

    await tester.tap(find.text('Show all 8 stops'));
    await tester.pumpAndSettle();

    expect(find.text('Cairo'), findsWidgets);
    expect(find.text('Show fewer'), findsOneWidget);
  });

  testWidgets('a booking whose pickup and drop-off were never recorded still '
      'lists the corridor, unbadged', (tester) async {
    await _pump(tester, _trip(stops: _corridor(boarding: -1, dropoff: -1)));

    expect(find.text('Banha'), findsWidgets);
    expect(find.text('Your stop'), findsNothing);
    expect(find.text('Your drop-off'), findsNothing);
  });
}
