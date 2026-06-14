import '../repositories/support_repository.dart';
import '../entities/support_workspace.dart';

class GetSupportWorkspaceUseCase {
  final SupportRepository _repository;

  const GetSupportWorkspaceUseCase(this._repository);

  Future<SupportWorkspace> call() {
    return _repository.getWorkspace();
  }
}
