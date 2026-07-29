import '../repositories/client_auth_repository.dart';

class UpdatePasswordUseCase {
  final ClientAuthRepository _repository;

  const UpdatePasswordUseCase(this._repository);

  Future<void> call(String newPassword) {
    return _repository.updatePassword(newPassword);
  }
}
