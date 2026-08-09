import '../../domain/entities/auth_method.dart';
import '../../domain/entities/auth_method_failure.dart';
import '../models/otp_challenge_model.dart';
import '../models/social_auth_result_model.dart';
import 'phone_auth_datasource.dart';

/// The [PhoneAuthDatasource] this build ships with: no SMS provider is
/// configured, so both calls fail as [AuthMethodFailure.unavailable].
///
/// Same contract as [PendingSocialAuthDatasource] — it keeps the graph real
/// without inventing a code that was never sent. A stub that returned an
/// [OtpChallengeModel] would start a countdown for an SMS that is not coming,
/// which is worse than an honest refusal.
///
/// The real implementation belongs in `supabase_phone_auth_datasource.dart`:
/// `signInWithOtp(phone: …)` then `verifyOTP(type: OtpType.sms, …)`, with an
/// SMS provider configured in Supabase Auth (Twilio/Vonage/MessageBird) and the
/// project's rate limits mirrored into [OtpChallengeModel.resendAfterSeconds]
/// so the screen's countdown matches what the backend will actually accept.
///
/// Two things the real version must get right, because the UI already assumes
/// them: Supabase returns the *same* generic error for a wrong code and an
/// expired one, so distinguishing [AuthMethodFailure.invalidCode] from
/// `expiredCode` needs the challenge's own `expiresAt`; and a phone that
/// already belongs to an email/password account must resolve to that same
/// `clients` row rather than creating a second one.
class PendingPhoneAuthDatasource implements PhoneAuthDatasource {
  const PendingPhoneAuthDatasource();

  @override
  Future<OtpChallengeModel> sendOtp(String phone) =>
      throw const AuthMethodException(
        AuthMethodFailure.unavailable,
        method: AuthMethod.phoneOtp,
        details: 'No SMS provider is configured in this build.',
      );

  @override
  Future<SocialAuthResultModel> verifyOtp({
    required String phone,
    required String code,
  }) => throw const AuthMethodException(
    AuthMethodFailure.unavailable,
    method: AuthMethod.phoneOtp,
    details: 'No SMS provider is configured in this build.',
  );
}
