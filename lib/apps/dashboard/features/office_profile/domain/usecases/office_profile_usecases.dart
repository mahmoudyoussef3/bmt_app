import '../entities/office_profile.dart';
import '../repositories/office_profile_repository.dart';

class GetOfficeProfileUseCase {
  const GetOfficeProfileUseCase(this._repository);
  final OfficeProfileRepository _repository;
  Future<OfficeProfile> call() => _repository.getProfile();
}

class UpdateOfficeProfileUseCase {
  const UpdateOfficeProfileUseCase(this._repository);
  final OfficeProfileRepository _repository;
  Future<OfficeProfile> call(OfficeProfileEdit edit) =>
      _repository.updateProfile(edit);
}
