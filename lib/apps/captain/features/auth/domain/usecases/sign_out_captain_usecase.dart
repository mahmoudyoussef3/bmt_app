import '../repositories/captain_auth_repository.dart';

class SignOutCaptainUseCase {
  const SignOutCaptainUseCase(this._repository);

  final CaptainAuthRepository _repository;

  Future<void> call() => _repository.signOut();
}
