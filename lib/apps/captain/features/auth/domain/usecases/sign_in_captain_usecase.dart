import '../repositories/captain_auth_repository.dart';

class SignInCaptainUseCase {
  const SignInCaptainUseCase(this._repository);

  final CaptainAuthRepository _repository;

  Future<void> call({required String phone}) =>
      _repository.signInWithPhone(phone);
}
