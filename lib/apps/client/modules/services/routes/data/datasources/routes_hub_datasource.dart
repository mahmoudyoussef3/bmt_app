import '../models/routes_hub_data_model.dart';

abstract class RoutesHubDatasource {
  Future<RoutesHubDataModel> getRoutesHubData();
}
