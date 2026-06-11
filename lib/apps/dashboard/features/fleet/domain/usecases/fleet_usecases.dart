import '../../shared/domain/entities/fleet_workspace.dart';
import '../repositories/fleet_repository.dart';

class GetFleetWorkspaceUseCase {
  final FleetRepository _repository;

  const GetFleetWorkspaceUseCase(this._repository);

  Future<FleetWorkspace> call() => _repository.getWorkspace();
}
