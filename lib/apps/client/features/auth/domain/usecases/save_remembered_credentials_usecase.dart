import '../repositories/remember_me_repository.dart';

class SaveRememberedCredentialsUseCase {
  const SaveRememberedCredentialsUseCase(this._repository);

  final RememberMeRepository _repository;

  Future<void> call({required String email, required String password}) {
    return _repository.save(email: email, password: password);
  }
}
