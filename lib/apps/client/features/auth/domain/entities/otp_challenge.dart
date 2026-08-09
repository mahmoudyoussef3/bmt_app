/// A one-time code that has been sent to a phone number and is waiting to be
/// entered.
///
/// The two timestamps are what the OTP screen is built around: [expiresAt]
/// decides when the entered code becomes pointless, [resendAvailableAt] decides
/// when "resend" stops being a no-op. Both are absolute instants rather than
/// remaining seconds, so a countdown stays correct when the app is backgrounded
/// mid-wait and resumes a minute later.
class OtpChallenge {
  const OtpChallenge({
    required this.phone,
    required this.expiresAt,
    required this.resendAvailableAt,
    this.codeLength = 6,
  });

  /// E.164, exactly as `ContactValidation.normalizeEgyptianPhone` produces it.
  final String phone;

  /// How many digits the rider must type. The screen draws this many boxes
  /// rather than assuming six, because the provider decides the length.
  final int codeLength;

  final DateTime expiresAt;

  /// The provider throttles resends; asking earlier than this is rejected, so
  /// the button stays inert until it passes.
  final DateTime resendAvailableAt;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  bool canResendAt(DateTime now) => !now.isBefore(resendAvailableAt);

  /// Seconds left before "resend" becomes tappable; `0` once it is.
  int secondsUntilResendAt(DateTime now) {
    final remaining = resendAvailableAt.difference(now).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}
