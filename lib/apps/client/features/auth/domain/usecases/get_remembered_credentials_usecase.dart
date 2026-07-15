import '../entities/remembered_credentials.dart';
import '../repositories/remember_me_repository.dart';

class GetRememberedCredentialsUseCase {
  const GetRememberedCredentialsUseCase(this._repository);

  final RememberMeRepository _repository;

  Future<RememberedCredentials?> call() => _repository.read();
}
