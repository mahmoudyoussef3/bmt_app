import '../repositories/client_auth_repository.dart';

class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repository);

  final ClientAuthRepository _repository;

  Future<void> call({required String phone, required String code}) {
    return _repository.verifyOtp(phone: phone, code: code);
  }
}
