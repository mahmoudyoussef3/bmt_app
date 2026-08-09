import '../models/otp_challenge_model.dart';
import '../models/social_auth_result_model.dart';

/// Talks to whatever sends and checks SMS codes.
///
/// [phone] is always E.164 by the time it arrives here — the use cases
/// normalise before calling, so an implementation never has to guess whether
/// `0101…` means Egypt.
abstract class PhoneAuthDatasource {
  Future<OtpChallengeModel> sendOtp(String phone);

  Future<SocialAuthResultModel> verifyOtp({
    required String phone,
    required String code,
  });
}
