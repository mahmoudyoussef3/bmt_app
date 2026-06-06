import '../entities/otp_request.dart';
import '../repositories/client_auth_repository.dart';

class RequestOtpUseCase {
  const RequestOtpUseCase(this._repository);

  final ClientAuthRepository _repository;

  Future<OtpRequest> call({required String dialCode, required String phone}) {
    return _repository.requestOtp(dialCode: dialCode, phone: phone);
  }
}
