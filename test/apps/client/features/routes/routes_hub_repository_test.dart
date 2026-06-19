import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/routes/data/datasources/routes_hub_datasource.dart';
import 'package:bmt_app/apps/client/features/routes/data/models/routes_hub_data_model.dart';
import 'package:bmt_app/apps/client/features/routes/data/repositories/routes_hub_repository_impl.dart';
import 'package:bmt_app/apps/client/features/routes/domain/usecases/get_routes_hub_data_usecase.dart';

void main() {
  group('Client routes hub', () {
    test('returns hub copy, actions, and booking flow steps', () async {
      const repository = RoutesHubRepositoryImpl(_FakeRoutesHubDatasource());

      final data = await GetRoutesHubDataUseCase(repository)();

      expect(data.title, 'Routes');
      expect(data.searchAction.route, '/booking/search');
      expect(data.popularRoutesAction.arguments['date'], 'Today, Jun 3');
      expect(data.flowSteps.map((step) => step.title), [
        'Search',
        'Compare',
        'Select seat',
        'Pay',
      ]);
    });
  });
}

class _FakeRoutesHubDatasource implements RoutesHubDatasource {
  const _FakeRoutesHubDatasource();

  @override
  Future<RoutesHubDataModel> getRoutesHubData() async {
    return const RoutesHubDataModel(
      title: 'Routes',
      subtitle: 'Search, compare, and book your commute',
      searchTitle: 'Where are you going?',
      searchDescription:
          'Enter pickup, destination, date and time to see available trips.',
      searchAction: RoutesHubActionModel(route: '/booking/search'),
      popularRoutesAction: RoutesHubActionModel(
        route: '/booking/popular-routes',
        arguments: {
          'pickup': '',
          'destination': '',
          'date': 'Today, Jun 3',
          'time': '',
        },
      ),
      flowSteps: [
        RoutesHubFlowStepModel(
          step: 1,
          title: 'Search',
          subtitle: 'Pickup, destination, date & time',
        ),
        RoutesHubFlowStepModel(
          step: 2,
          title: 'Compare',
          subtitle: 'Routes and vehicles',
        ),
        RoutesHubFlowStepModel(
          step: 3,
          title: 'Select seat',
          subtitle: 'Choose your place on board',
        ),
        RoutesHubFlowStepModel(
          step: 4,
          title: 'Pay',
          subtitle: 'Secure checkout',
        ),
      ],
    );
  }
}
