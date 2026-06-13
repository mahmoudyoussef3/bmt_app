import '../repositories/client_auth_repository.dart';

class SignInWithEmailUseCase {
  final ClientAuthRepository repository;

  SignInWithEmailUseCase(this.repository);

  Future<void> call({
    required String email,
    required String password,
  }) async {
    return repository.signInWithEmail(email: email, password: password);
  }
}
