enum AuthSubmissionStatus { initial, loading, success, failure }

class ClientAuthState {
  const ClientAuthState({
    this.signInStatus = AuthSubmissionStatus.initial,
    this.signUpStatus = AuthSubmissionStatus.initial,
    this.signOutStatus = AuthSubmissionStatus.initial,
    this.signInError,
    this.signUpError,
    this.signOutError,
  });

  final AuthSubmissionStatus signInStatus;
  final AuthSubmissionStatus signUpStatus;

  /// Signing out is a real, awaited operation — the rider must see it running
  /// and must be told when it fails, instead of tapping a button that silently
  /// leaves them signed in.
  final AuthSubmissionStatus signOutStatus;

  final String? signInError;
  final String? signUpError;
  final String? signOutError;

  ClientAuthState copyWith({
    AuthSubmissionStatus? signInStatus,
    AuthSubmissionStatus? signUpStatus,
    AuthSubmissionStatus? signOutStatus,
    String? signInError,
    String? signUpError,
    String? signOutError,
    bool clearSignInError = false,
    bool clearSignUpError = false,
    bool clearSignOutError = false,
  }) {
    return ClientAuthState(
      signInStatus: signInStatus ?? this.signInStatus,
      signUpStatus: signUpStatus ?? this.signUpStatus,
      signOutStatus: signOutStatus ?? this.signOutStatus,
      signInError: clearSignInError ? null : signInError ?? this.signInError,
      signUpError: clearSignUpError ? null : signUpError ?? this.signUpError,
      signOutError: clearSignOutError ? null : signOutError ?? this.signOutError,
    );
  }
}
