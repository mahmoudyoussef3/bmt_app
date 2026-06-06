import '../../domain/entities/client_registration.dart';
import '../models/otp_request_model.dart';

class MockClientAuthDatasource {
  const MockClientAuthDatasource();

  Future<OtpRequestModel> requestOtp({
    required String dialCode,
    required String phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8 || digits.length > 11) {
      throw const FormatException('Enter a valid mobile number (8–11 digits)');
    }
    return OtpRequestModel(formattedPhone: '$dialCode ${phone.trim()}');
  }

  Future<void> verifyOtp({required String phone, required String code}) async {
    if (code == '000000') {
      throw const FormatException(
        'Invalid code. Please try again or request a new code.',
      );
    }
  }

  Future<void> register(ClientRegistration registration) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final emailOk = RegExp(
      r'^[^@]+@[^@]+\.[^@]+',
    ).hasMatch(registration.email.trim());
    final phoneOk =
        registration.phone.replaceAll(RegExp(r'\D'), '').length >= 8;
    if (registration.fullName.trim().length < 2 || !emailOk || !phoneOk) {
      throw const FormatException('Complete the required profile fields');
    }
  }
}
