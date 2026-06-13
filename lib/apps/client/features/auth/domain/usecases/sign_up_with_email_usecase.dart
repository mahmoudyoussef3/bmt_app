import '../repositories/client_auth_repository.dart';

class SignUpWithEmailUseCase {
  final ClientAuthRepository repository;

  SignUpWithEmailUseCase(this.repository);

  Future<void> call({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    return repository.signUpWithEmail(
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
    );
  }
}
