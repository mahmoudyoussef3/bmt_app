import '../../../../../../core/network/api_result.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<ApiResult<void>> call() {
    return repository.logout();
  }
}
