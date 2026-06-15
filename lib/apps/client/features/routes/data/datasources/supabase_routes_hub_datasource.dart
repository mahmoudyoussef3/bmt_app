import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/routes_hub_data_model.dart';

import 'routes_hub_datasource.dart';

class SupabaseRoutesHubDatasource implements RoutesHubDatasource {
  final SupabaseClient _supabase;

  const SupabaseRoutesHubDatasource(this._supabase);

  Future<RoutesHubDataModel> getRoutesHubData() async {
    // The RoutesHubDataModel configures the UI for the routes tab.
    // While the text is static, the actual route searching and mapping
    // is now securely powered by operation_routes via the Booking flow.
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
