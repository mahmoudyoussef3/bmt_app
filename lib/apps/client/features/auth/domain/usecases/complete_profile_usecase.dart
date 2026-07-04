import '../../../../../../core/network/api_result.dart';
import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class CompleteProfileUseCase {
  final AuthRepository repository;

  CompleteProfileUseCase(this.repository);

  Future<ApiResult<UserProfile>> call({
    required String phone,
    required String fullName,
    String? email,
    String? gender,
    String? preferredPickupArea,
  }) async {
    return await repository.completeProfile(
      phone: phone,
      fullName: fullName,
      email: email,
      gender: gender,
      preferredPickupArea: preferredPickupArea,
    );
  }
}
