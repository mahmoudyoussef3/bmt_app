import '../entities/client_profile.dart';
import '../repositories/profile_repository.dart';

class GetProfileDataUseCase {
  const GetProfileDataUseCase(this._repository);

  final ProfileRepository _repository;

  Future<ClientProfile> call() => _repository.getProfile();
}
