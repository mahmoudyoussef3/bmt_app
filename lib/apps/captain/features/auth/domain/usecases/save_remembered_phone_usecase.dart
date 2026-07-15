import '../repositories/captain_remember_me_repository.dart';

class SaveRememberedPhoneUseCase {
  const SaveRememberedPhoneUseCase(this._repository);

  final CaptainRememberMeRepository _repository;

  Future<void> call(String phone) => _repository.save(phone);
}
