import '../entities/dashboard_home_data.dart';
import '../repositories/dashboard_home_repository.dart';

class GetDashboardHomeUseCase {
  final DashboardHomeRepository _repository;

  const GetDashboardHomeUseCase(this._repository);

  Future<DashboardHomeData> call() {
    return _repository.getHomeData();
  }
}
