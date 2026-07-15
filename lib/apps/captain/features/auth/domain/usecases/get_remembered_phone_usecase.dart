import '../repositories/captain_remember_me_repository.dart';

class GetRememberedPhoneUseCase {
  const GetRememberedPhoneUseCase(this._repository);

  final CaptainRememberMeRepository _repository;

  Future<String?> call() => _repository.read();
}
