import '../../../../../../core/network/api_result.dart';
import '../repositories/auth_repository.dart';

class VerifyPhoneUseCase {
  final AuthRepository repository;

  VerifyPhoneUseCase(this.repository);

  Future<ApiResult<void>> call(String phoneNumber) async {
    return await repository.verifyPhone(phoneNumber);
  }
}
