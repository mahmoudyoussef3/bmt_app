import '../../domain/entities/otp_challenge.dart';

/// The provider's answer to "send a code to this number".
///
/// Providers report the two waits differently — some return absolute instants,
/// most return "expires in N seconds" — so the model takes durations and the
/// entity holds instants. Converting once, here, is what lets the OTP screen's
/// countdown survive the app being backgrounded: a stored "30 seconds left"
/// would still say 30 on resume.
class OtpChallengeModel {
  const OtpChallengeModel({
    required this.phone,
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
    this.codeLength = 6,
  });

  factory OtpChallengeModel.fromJson(Map<String, dynamic> json) {
    int seconds(Object? value, int fallback) =>
        int.tryParse(value?.toString() ?? '') ?? fallback;

    return OtpChallengeModel(
      phone: json['phone']?.toString() ?? '',
      expiresInSeconds: seconds(json['expires_in'], 300),
      resendAfterSeconds: seconds(json['resend_after'], 30),
      codeLength: seconds(json['code_length'], 6),
    );
  }

  final String phone;
  final int expiresInSeconds;
  final int resendAfterSeconds;
  final int codeLength;

  /// [sentAt] is passed in rather than read from `DateTime.now()` so the
  /// conversion is deterministic in tests and anchored to when the request
  /// actually completed, not to when the mapping happened to run.
  OtpChallenge toEntity({required DateTime sentAt}) => OtpChallenge(
    phone: phone,
    codeLength: codeLength,
    expiresAt: sentAt.add(Duration(seconds: expiresInSeconds)),
    resendAvailableAt: sentAt.add(Duration(seconds: resendAfterSeconds)),
  );
}
