import '../../domain/entities/routes_hub_data.dart';
import '../../domain/repositories/routes_hub_repository.dart';
import '../datasources/routes_hub_datasource.dart';

class RoutesHubRepositoryImpl implements RoutesHubRepository {
  const RoutesHubRepositoryImpl(this._datasource);

  final RoutesHubDatasource _datasource;

  @override
  Future<RoutesHubData> getRoutesHubData() async {
    final data = await _datasource.getRoutesHubData();
    return data.toEntity();
  }
}
