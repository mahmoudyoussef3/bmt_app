import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/routes/data/datasources/mock_routes_hub_datasource.dart';
import 'package:bmt_app/apps/client/features/routes/data/repositories/routes_hub_repository_impl.dart';
import 'package:bmt_app/apps/client/features/routes/domain/usecases/get_routes_hub_data_usecase.dart';

void main() {
  group('Client routes hub', () {
    test('returns hub copy, actions, and booking flow steps', () async {
      const repository = RoutesHubRepositoryImpl(MockRoutesHubDatasource());

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
