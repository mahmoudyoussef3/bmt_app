import 'package:bmt_app/core/validation/contact_validation.dart';

import '../entities/auth_method.dart';
import '../entities/auth_method_failure.dart';
import '../entities/social_auth_result.dart';
import '../repositories/phone_auth_repository.dart';

/// Exchanges the code the rider typed for a session.
///
/// A short or non-numeric code is rejected here instead of being spent on a
/// round trip — providers count every wrong attempt against the rate limit, so
/// "you typed four digits" must not cost one of the three tries they get.
class VerifyPhoneOtpUseCase {
  const VerifyPhoneOtpUseCase(this.repository);

  final PhoneAuthRepository repository;

  Future<SocialAuthResult> call({
    required String phone,
    required String code,
    int codeLength = 6,
  }) {
    final digits = code.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != codeLength) {
      throw const AuthMethodException(
        AuthMethodFailure.invalidCode,
        method: AuthMethod.phoneOtp,
      );
    }
    return repository.verifyOtp(
      phone: ContactValidation.normalizeEgyptianPhone(phone),
      code: digits,
    );
  }
}
