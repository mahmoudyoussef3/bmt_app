import 'package:bmt_app/core/validation/contact_validation.dart';

import '../entities/auth_method.dart';
import '../entities/auth_method_failure.dart';
import '../entities/otp_challenge.dart';
import '../repositories/phone_auth_repository.dart';

/// Sends the one-time code, normalising the rider's typing first.
///
/// The normalisation belongs here rather than in the screen: sign-up already
/// stores `clients.phone` through [ContactValidation.normalizeEgyptianPhone],
/// and a rider who signs up as `01012345678` must reach the same account when
/// they later type `+20 10 1234 5678` into the OTP screen.
class SendPhoneOtpUseCase {
  const SendPhoneOtpUseCase(this.repository);

  final PhoneAuthRepository repository;

  Future<OtpChallenge> call(String phone) {
    final normalized = ContactValidation.normalizeEgyptianPhone(phone);
    if (!ContactValidation.isValidEgyptianPhone(normalized)) {
      throw const AuthMethodException(
        AuthMethodFailure.invalidPhone,
        method: AuthMethod.phoneOtp,
      );
    }
    return repository.sendOtp(normalized);
  }
}
