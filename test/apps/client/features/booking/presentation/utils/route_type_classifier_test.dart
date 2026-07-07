import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/route_type_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

RouteOptionData _routeWithStops(int stopCount) {
  return RouteOptionData(
    id: 'r1',
    routeName: 'Test Route',
    pickup: 'A',
    destination: 'B',
    distance: '10 km',
    duration: '30 min',
    availableSeats: 4,
    startingPrice: r'$10',
    priceRange: r'$10-$15',
    availableTrips: const [],
    points: List.generate(
      stopCount,
      (index) => RoutePointData(name: 'Stop $index', order: index),
    ),
  );
}

void main() {
  group('classifyRouteType', () {
    test('classifies a route with no intermediate stops as direct', () {
      expect(classifyRouteType(_routeWithStops(0)), RouteType.direct);
    });

    test(
      'classifies a route at the direct-stop threshold (2) as direct',
      () {
        expect(classifyRouteType(_routeWithStops(2)), RouteType.direct);
      },
    );

    test('classifies a route with more than 2 stops as multi-stop', () {
      expect(classifyRouteType(_routeWithStops(3)), RouteType.multiStop);
    });
  });

  group('routeTypeLabel', () {
    test('labels direct and multi-stop routes', () {
      expect(routeTypeLabel(RouteType.direct), 'Direct');
      expect(routeTypeLabel(RouteType.multiStop), 'Multi-stop');
    });
  });
}
