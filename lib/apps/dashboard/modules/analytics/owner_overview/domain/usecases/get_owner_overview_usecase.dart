import '../entities/owner_overview.dart';
import '../repositories/owner_overview_repository.dart';

class GetOwnerOverviewUseCase {
  final OwnerOverviewRepository _repository;

  const GetOwnerOverviewUseCase(this._repository);

  Future<OwnerOverview> call() => _repository.getOverview();
}
