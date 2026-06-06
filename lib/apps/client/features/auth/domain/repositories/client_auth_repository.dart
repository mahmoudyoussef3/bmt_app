import '../entities/client_registration.dart';
import '../entities/otp_request.dart';

abstract class ClientAuthRepository {
  Future<OtpRequest> requestOtp({
    required String dialCode,
    required String phone,
  });

  Future<void> verifyOtp({required String phone, required String code});

  Future<void> register(ClientRegistration registration);
}
