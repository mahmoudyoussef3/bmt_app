import '../repositories/client_auth_repository.dart';

class SendPasswordResetEmailUseCase {
  final ClientAuthRepository _repository;

  const SendPasswordResetEmailUseCase(this._repository);

  Future<void> call(String email) {
    return _repository.sendPasswordResetEmail(email);
  }
}
