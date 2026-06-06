import '../entities/routes_hub_data.dart';
import '../repositories/routes_hub_repository.dart';

class GetRoutesHubDataUseCase {
  const GetRoutesHubDataUseCase(this._repository);

  final RoutesHubRepository _repository;

  Future<RoutesHubData> call() {
    return _repository.getRoutesHubData();
  }
}
