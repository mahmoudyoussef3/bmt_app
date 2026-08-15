import 'package:bmt_app/core/pricing/trip_pricing_resolver.dart';
import 'package:bmt_app/core/pricing/trip_stop_pair_price_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the id-namespace bug that made the Client app show —
/// and `confirm_seat_booking_v2` charge — the flat `transport_packages`
/// catalog price instead of the Dashboard's per-stop-pair `trip_pricing` fare.
///
/// `trip_pricing` is keyed by `trip_route_points.id` (the trip's snapshot of
/// the route's stations); the rider picks stops from `route_stations`. Without
/// translating between the two, no pricing row ever matched the rider's pair.
void main() {
  // El-Marg -> AUC, as the Dashboard stores it: trip_route_points ids.
  const elMargTripPoint = 'c3798ba0-267f-407e-8665-3c0df5ac4da7';
  const aucTripPoint = '612a8bc9-c3d8-43bd-a167-7a2560607e8c';

  // The same two stops, as the rider's wizard knows them: route_stations ids.
  const elMargStation = '50dfe4c0-9a8e-47b2-a83c-aba6ae684c50';
  const aucStation = '4e934b25-9a1d-4409-bbd0-0d9e89f0ea64';

  final tripRoutePoints = [
    {'id': elMargTripPoint, 'route_point_id': elMargStation},
    {'id': aucTripPoint, 'route_point_id': aucStation},
  ];

  final tripPricing = [
    {
      'from_point_id': elMargTripPoint,
      'to_point_id': aucTripPoint,
      'one_time_price': 100,
      'is_active': true,
      'trip_package_prices': [
        {'package_id': 'pkg-five-days', 'price': 200},
        {'package_id': 'pkg-ten-days', 'price': 375},
        {'package_id': 'pkg-monthly', 'price': 400},
        {'package_id': 'pkg-three-months', 'price': 450},
      ],
    },
  ];

  group('routeStationIdsFromJson', () {
    test('maps each trip route point onto the route station it snapshotted', () {
      expect(routeStationIdsFromJson(tripRoutePoints), {
        elMargTripPoint: elMargStation,
        aucTripPoint: aucStation,
      });
    });

    test('skips rows missing either side of the translation', () {
      final map = routeStationIdsFromJson([
        {'id': elMargTripPoint, 'route_point_id': null},
        {'id': '', 'route_point_id': aucStation},
        {'id': aucTripPoint, 'route_point_id': aucStation},
      ]);

      expect(map, {aucTripPoint: aucStation});
    });

    test('tolerates a missing or malformed join', () {
      expect(routeStationIdsFromJson(null), isEmpty);
      expect(routeStationIdsFromJson('not a list'), isEmpty);
    });
  });

  group('tripStopPairPricesFromJson', () {
    test('rekeys pricing rows onto the station ids the rider selects', () {
      final pricing = tripStopPairPricesFromJson(
        tripPricing,
        stationIds: routeStationIdsFromJson(tripRoutePoints),
      );

      expect(pricing.single.fromPointId, elMargStation);
      expect(pricing.single.toPointId, aucStation);
      expect(pricing.single.packagePrices['pkg-monthly'], 400);
    });

    test('resolves the Dashboard fare for the rider stop pair', () {
      final pricing = tripStopPairPricesFromJson(
        tripPricing,
        stationIds: routeStationIdsFromJson(tripRoutePoints),
      );

      expect(
        TripPricingResolver.oneTimeFareFor(pricing, elMargStation, aucStation),
        100,
      );
      // "One Month" package's own price, NOT the 3000 catalog price the
      // Client used to fall back to.
      expect(
        TripPricingResolver.packageFareFor(
          pricing,
          elMargStation,
          aucStation,
          'pkg-monthly',
          30,
          44,
        ),
        400,
      );
    });

    test('without the translation no row matches — the original bug', () {
      final pricing = tripStopPairPricesFromJson(tripPricing);

      expect(
        TripPricingResolver.oneTimeFareFor(pricing, elMargStation, aucStation),
        isNull,
      );
    });

    test('leaves ids untouched when the point is absent from the map', () {
      final pricing = tripStopPairPricesFromJson(tripPricing, stationIds: {});

      expect(pricing.single.fromPointId, elMargTripPoint);
      expect(pricing.single.toPointId, aucTripPoint);
    });
  });
}
