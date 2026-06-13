import '../../domain/entities/client_registration.dart';
import '../models/otp_request_model.dart';

abstract class ClientAuthDatasource {
  Future<OtpRequestModel> requestOtp({
    required String dialCode,
    required String phone,
  });

  Future<void> verifyOtp({required String phone, required String code});

  Future<void> register(ClientRegistration registration);
}
