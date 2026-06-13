enum AuthSubmissionStatus { initial, loading, success, failure }

class ClientAuthState {
  const ClientAuthState({
    this.signInStatus = AuthSubmissionStatus.initial,
    this.signUpStatus = AuthSubmissionStatus.initial,
    this.signInError,
    this.signUpError,
  });

  final AuthSubmissionStatus signInStatus;
  final AuthSubmissionStatus signUpStatus;
  final String? signInError;
  final String? signUpError;

  ClientAuthState copyWith({
    AuthSubmissionStatus? signInStatus,
    AuthSubmissionStatus? signUpStatus,
    String? signInError,
    String? signUpError,
    bool clearSignInError = false,
    bool clearSignUpError = false,
  }) {
    return ClientAuthState(
      signInStatus: signInStatus ?? this.signInStatus,
      signUpStatus: signUpStatus ?? this.signUpStatus,
      signInError: clearSignInError ? null : signInError ?? this.signInError,
      signUpError: clearSignUpError ? null : signUpError ?? this.signUpError,
    );
  }
}
