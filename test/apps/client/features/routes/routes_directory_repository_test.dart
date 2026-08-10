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
    return RouteDetailsModel.fromJson(
      {
        'id': routeId,
        'name': 'Cairo Express',
        'start_city': 'Cairo',
        'end_city': 'Alexandria',
        'route_code': 'CAI-ALX',
        'status': 'active',
        'office': {'id': 'o1', 'name': 'Nile Express', 'rating': 4.5},
      },
      stops: const [],
    );
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
