import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/routes/data/datasources/routes_directory_datasource.dart';
import 'package:bmt_app/apps/client/features/routes/data/models/route_details_model.dart';
import 'package:bmt_app/apps/client/features/routes/data/models/route_stop_model.dart';
import 'package:bmt_app/apps/client/features/routes/data/models/route_summary_model.dart';
import 'package:bmt_app/apps/client/features/routes/data/repositories/routes_directory_repository_impl.dart';

class _FakeRoutesDirectoryDatasource implements RoutesDirectoryDatasource {
  const _FakeRoutesDirectoryDatasource();

  @override
  Future<List<RouteSummaryModel>> fetchRoutes() async {
    return [
      RouteSummaryModel.fromJson({
        'id': 'r1',
        'name': 'Cairo Express',
        'start_city': 'Cairo',
        'end_city': 'Alexandria',
        'distance': '220 km',
        'duration': '3h',
        'office': {'id': 'o1', 'name': 'Nile Express', 'logo_url': null},
      }),
    ];
  }

  @override
  Future<RouteDetailsModel> fetchRouteDetails(String routeId) async {
    return RouteDetailsModel.fromJson({
      'id': routeId,
      'name': 'Cairo Express',
      'start_city': 'Cairo',
      'end_city': 'Alexandria',
      'route_code': 'CAI-ALX',
      'status': 'active',
      'office': {'id': 'o1', 'name': 'Nile Express', 'rating': 4.5},
    }, stops: const []);
  }
}

void main() {
  group('RoutesDirectoryRepositoryImpl', () {
    test('getRoutes passes the datasource result through', () async {
      const repository = RoutesDirectoryRepositoryImpl(
        _FakeRoutesDirectoryDatasource(),
      );

      final routes = await repository.getRoutes();

      expect(routes.single.name, 'Cairo Express');
      expect(routes.single.officeName, 'Nile Express');
    });

    test('getRouteDetails passes the datasource result through', () async {
      const repository = RoutesDirectoryRepositoryImpl(
        _FakeRoutesDirectoryDatasource(),
      );

      final details = await repository.getRouteDetails('r1');

      expect(details.routeCode, 'CAI-ALX');
      expect(details.officeRating, 4.5);
    });
  });

  group('RouteSummaryModel.fromJson', () {
    test('reads an embedded office map', () {
      final model = RouteSummaryModel.fromJson({
        'id': 'r1',
        'name': 'Cairo Express',
        'start_city': 'Cairo',
        'end_city': 'Alexandria',
        'office': {'id': 'o1', 'name': 'Nile Express', 'logo_url': 'x.png'},
      });

      expect(model.officeId, 'o1');
      expect(model.officeName, 'Nile Express');
      expect(model.officeLogoUrl, 'x.png');
    });

    test('degrades to defaults when the office is missing', () {
      final model = RouteSummaryModel.fromJson({
        'id': 'r1',
        'name': 'Cairo Express',
        'start_city': 'Cairo',
        'end_city': 'Alexandria',
      });

      expect(model.officeId, '');
      expect(model.officeName, '');
      expect(model.officeLogoUrl, isNull);
      expect(model.stops, isEmpty);
    });

    test('orders the embedded stations by sort_order', () {
      final model = RouteSummaryModel.fromJson({
        'id': 'r1',
        'name': 'Cairo Express',
        'start_city': 'Cairo',
        'end_city': 'Mansoura',
        'stops': [
          {'id': 's3', 'name': 'Banha', 'sort_order': 3},
          {'id': 's1', 'name': 'Cairo', 'sort_order': 1},
          {'id': 's2', 'name': 'Shibin El Kom', 'sort_order': 2},
        ],
      });

      expect(model.stops.map((stop) => stop.name), [
        'Cairo',
        'Shibin El Kom',
        'Banha',
      ]);
    });

    test('drops unnamed stations so the ends of the list stay meaningful', () {
      final model = RouteSummaryModel.fromJson({
        'id': 'r1',
        'name': 'Cairo Express',
        'start_city': 'Cairo',
        'end_city': 'Mansoura',
        'stops': [
          {'id': 's1', 'name': 'Cairo', 'sort_order': 1},
          {'id': 's2', 'sort_order': 2},
          {'id': 's3', 'name': '  ', 'sort_order': 3},
          {'id': 's4', 'name': 'Mansoura', 'sort_order': 4},
        ],
      });

      expect(model.stops.map((stop) => stop.name), ['Cairo', 'Mansoura']);
    });

    test('survives a missing or malformed stations relation', () {
      Map<String, dynamic> row(Object? stops) => {
        'id': 'r1',
        'name': 'Cairo Express',
        'start_city': 'Cairo',
        'end_city': 'Mansoura',
        'stops': stops,
      };

      expect(RouteSummaryModel.fromJson(row(null)).stops, isEmpty);
      expect(RouteSummaryModel.fromJson(row('nonsense')).stops, isEmpty);
      expect(RouteSummaryModel.fromJson(row(const [])).stops, isEmpty);
    });
  });

  group('RouteStopModel.fromJson', () {
    test('maps sort_order to order and defaults pickup/dropoff to true', () {
      final model = RouteStopModel.fromJson({
        'id': 's1',
        'name': 'Ramses Station',
        'sort_order': 2,
      });

      expect(model.order, 2);
      expect(model.pickupAllowed, isTrue);
      expect(model.dropoffAllowed, isTrue);
    });

    test('respects explicit pickup/dropoff restrictions', () {
      final model = RouteStopModel.fromJson({
        'id': 's1',
        'name': 'Ramses Station',
        'sort_order': 2,
        'pickup_allowed': false,
        'dropoff_allowed': true,
      });

      expect(model.pickupAllowed, isFalse);
      expect(model.dropoffAllowed, isTrue);
    });
  });
}
