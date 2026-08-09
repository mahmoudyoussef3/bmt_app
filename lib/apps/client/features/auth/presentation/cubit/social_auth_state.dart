import '../../domain/entities/auth_method.dart';
import '../../domain/entities/auth_method_failure.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/entities/social_auth_result.dart';

/// Where an alternative sign-in attempt currently stands.
///
/// Google and Apple both finish at [succeeded]; the flow that produced it is in
/// [SocialAuthState.method], so no `googleSuccess`/`appleSuccess` pair is
/// needed — two states that differ only by an enum the state already carries
/// would force every listener to handle both and get the same answer.
///
/// [cancelled] is separate from [failed] because it is not an error: the rider
/// closed the provider sheet on purpose and must not be shown a red banner for
/// it.
enum SocialAuthStatus {
  initial,
  loading,

  /// A session exists. [SocialAuthState.result] holds who signed in.
  succeeded,

  /// A code was sent. [SocialAuthState.challenge] holds when it expires and
  /// when a resend becomes allowed.
  otpSent,

  /// The code was accepted; [SocialAuthState.result] holds the session, exactly
  /// as for [succeeded]. Kept distinct so the OTP screen can play its own
  /// confirmation before navigating.
  otpVerified,

  cancelled,
  failed,
}

/// State for every sign-in method that is not email + password.
///
/// Follows [ClientAuthState]'s shape — a plain immutable class with `copyWith`
/// and intent-named transitions, not a freezed union — because that is what the
/// rest of this feature uses and a second state idiom inside one feature is a
/// tax on every reader.
///
/// The failure is carried as a typed [AuthMethodFailure], never a string: this
/// app is Arabic-first and the wording has to come from the ARB catalogue at
/// render time. `authErrorMessage` (the email/password path) predates
/// localization and is deliberately not reused here.
class SocialAuthState {
  const SocialAuthState({
    this.status = SocialAuthStatus.initial,
    this.method,
    this.result,
    this.challenge,
    this.failure,
  });

  final SocialAuthStatus status;

  /// Which method the current status is about. Set as soon as an attempt
  /// starts, so a spinner can be shown on the button that was actually tapped
  /// rather than on all three.
  final AuthMethod? method;

  final SocialAuthResult? result;

  /// The live OTP challenge, from [SocialAuthStatus.otpSent] onwards. The OTP
  /// screen reads its `resendAvailableAt` to drive the countdown and its
  /// `codeLength` to decide how many boxes to draw.
  final OtpChallenge? challenge;

  final AuthMethodFailure? failure;

  bool get isLoading => status == SocialAuthStatus.loading;

  /// True while [method] is the one being attempted — the test a provider
  /// button uses to decide whether *it* shows the spinner.
  bool isLoadingMethod(AuthMethod candidate) =>
      isLoading && method == candidate;

  SocialAuthState copyWith({
    SocialAuthStatus? status,
    AuthMethod? method,
    SocialAuthResult? result,
    OtpChallenge? challenge,
    AuthMethodFailure? failure,
    bool clearResult = false,
    bool clearChallenge = false,
    bool clearFailure = false,
  }) {
    return SocialAuthState(
      status: status ?? this.status,
      method: method ?? this.method,
      result: clearResult ? null : result ?? this.result,
      challenge: clearChallenge ? null : challenge ?? this.challenge,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  SocialAuthState loading(AuthMethod method) => copyWith(
    status: SocialAuthStatus.loading,
    method: method,
    clearFailure: true,
  );

  SocialAuthState succeeded(SocialAuthResult result) => copyWith(
    status: SocialAuthStatus.succeeded,
    method: result.method,
    result: result,
    clearFailure: true,
  );

  SocialAuthState otpSent(OtpChallenge challenge) => copyWith(
    status: SocialAuthStatus.otpSent,
    method: AuthMethod.phoneOtp,
    challenge: challenge,
    clearFailure: true,
  );

  SocialAuthState otpVerified(SocialAuthResult result) => copyWith(
    status: SocialAuthStatus.otpVerified,
    method: AuthMethod.phoneOtp,
    result: result,
    clearFailure: true,
  );

  SocialAuthState cancelled(AuthMethod method) => copyWith(
    status: SocialAuthStatus.cancelled,
    method: method,
    clearFailure: true,
  );

  SocialAuthState failed(AuthMethod method, AuthMethodFailure failure) =>
      copyWith(
        status: SocialAuthStatus.failed,
        method: method,
        failure: failure,
      );

  /// Clears an error without losing a challenge already in flight, so
  /// dismissing "wrong code" leaves the rider on the same OTP screen with the
  /// same countdown running.
  SocialAuthState errorDismissed() => copyWith(
    status: challenge == null
        ? SocialAuthStatus.initial
        : SocialAuthStatus.otpSent,
    clearFailure: true,
  );
}
