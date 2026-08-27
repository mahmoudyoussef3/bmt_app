import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/route_map_screen.dart';

import '../../client_test_app.dart';

/// The line's own map screen. Coordinates are left off the fixture on purpose:
/// they are what makes the map reach for tiles and road geometry, which the
/// test binding blocks. What is asserted here is the half the screen owns —
/// its header and the full station list under the map.
void main() {
  RouteOptionData route() {
    return const RouteOptionData(
      id: 'r-1',
      routeName: 'Banha - New Cairo',
      pickup: 'Banha',
      destination: 'New Cairo',
      distance: '86 km',
      duration: '1h 6m',
      availableSeats: 14,
      startingPrice: 'EGP 100',
      priceRange: 'EGP 100 - 140',
      availableTrips: [
        RouteTripOptionData(
          id: 't-1',
          departureTime: '07:30:00',
          arrivalTime: '08:36:00',
          availableSeats: 14,
          vehicleType: 'Hiace',
          price: 'EGP 100',
        ),
      ],
      points: [
        RoutePointData(
          name: 'Banha',
          order: 1,
          arrivalOffset: '00:00',
          departureOffset: '00:00',
        ),
        RoutePointData(
          name: 'Police Academy',
          order: 2,
          arrivalOffset: '00:41',
          departureOffset: '00:41',
        ),
        RoutePointData(
          name: 'New Cairo',
          order: 3,
          arrivalOffset: '01:06',
          departureOffset: '01:06',
        ),
      ],
    );
  }

  testWidgets('names the line and lists every station under the map', (
    tester,
  ) async {
    await tester.pumpWidget(clientTestApp(RouteMapScreen(route: route())));
    await tester.pump();

    expect(find.text('Route map'), findsOneWidget);
    expect(find.text('Banha - New Cairo'), findsOneWidget);
    expect(find.text('Police Academy'), findsOneWidget);
    // The station clocks come along, computed off the line's soonest trip.
    expect(find.text('Departs 7:30 AM'), findsOneWidget);
    expect(find.text('Arrives 8:36 AM'), findsOneWidget);
  });
}
