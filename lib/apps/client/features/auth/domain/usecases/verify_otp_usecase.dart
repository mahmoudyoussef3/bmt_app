import '../../../../../../core/network/api_result.dart';
import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<ApiResult<UserProfile?>> call(String phoneNumber, String otp) async {
    return await repository.verifyOtp(phoneNumber, otp);
  }
}
