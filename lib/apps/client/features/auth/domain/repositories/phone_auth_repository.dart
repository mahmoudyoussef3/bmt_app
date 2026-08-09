import '../entities/otp_challenge.dart';
import '../entities/social_auth_result.dart';

/// Passwordless sign-in by SMS: send a code, then exchange it for a session.
///
/// The two calls are deliberately independent. A rider can leave the OTP screen
/// and come back, or ask for a second code, without the app having to keep an
/// in-flight object alive between them — [sendOtp] returns everything the
/// verify step needs, and the phone number is the only thing that has to travel
/// between the two screens.
///
/// Implementations throw [AuthMethodException] with a phone-specific reason
/// ([AuthMethodFailure.invalidPhone], `invalidCode`, `expiredCode`,
/// `rateLimited`) so the OTP screen can point at the field that is wrong.
abstract class PhoneAuthRepository {
  /// [phone] must already be E.164 (`ContactValidation.normalizeEgyptianPhone`).
  Future<OtpChallenge> sendOtp(String phone);

  Future<SocialAuthResult> verifyOtp({
    required String phone,
    required String code,
  });
}
