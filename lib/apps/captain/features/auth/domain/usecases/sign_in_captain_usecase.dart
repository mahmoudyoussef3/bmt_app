import '../repositories/captain_auth_repository.dart';

class SignInCaptainUseCase {
  const SignInCaptainUseCase(this._repository);

  final CaptainAuthRepository _repository;

  Future<void> call({required String email, required String password}) =>
      _repository.signIn(email: email, password: password);
}
