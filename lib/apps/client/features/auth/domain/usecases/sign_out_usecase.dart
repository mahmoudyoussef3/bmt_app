import '../repositories/client_auth_repository.dart';

class SignOutUseCase {
  final ClientAuthRepository repository;

  SignOutUseCase(this.repository);

  Future<void> call() async {
    return repository.signOut();
  }
}
