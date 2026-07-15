import '../repositories/remember_me_repository.dart';

class ClearRememberedCredentialsUseCase {
  const ClearRememberedCredentialsUseCase(this._repository);

  final RememberMeRepository _repository;

  Future<void> call() => _repository.clear();
}
