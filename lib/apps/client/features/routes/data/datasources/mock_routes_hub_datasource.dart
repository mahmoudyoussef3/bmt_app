import '../models/routes_hub_data_model.dart';

class MockRoutesHubDatasource {
  const MockRoutesHubDatasource();

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
