import '../entities/client_registration.dart';
import '../repositories/client_auth_repository.dart';

class RegisterClientUseCase {
  const RegisterClientUseCase(this._repository);

  final ClientAuthRepository _repository;

  Future<void> call(ClientRegistration registration) {
    return _repository.register(registration);
  }
}
