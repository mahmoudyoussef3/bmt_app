import '../entities/routes_hub_data.dart';

abstract class RoutesHubRepository {
  Future<RoutesHubData> getRoutesHubData();
}
