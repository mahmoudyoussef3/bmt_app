enum ResetPasswordStatus {
  /// Waiting for Supabase to exchange the recovery link's code for a session
  /// (`AuthChangeEvent.passwordRecovery`). The submit form is hidden until
  /// this settles into [ready] or [linkInvalid].
  verifying,

  /// A recovery session is active; the new-password form can submit.
  ready,

  /// The recovery link never produced a session (expired/used/malformed).
  linkInvalid,

  loading,
  success,
  failure,
}

class ResetPasswordState {
  const ResetPasswordState({
    this.status = ResetPasswordStatus.verifying,
    this.errorMessage,
  });

  final ResetPasswordStatus status;
  final String? errorMessage;

  ResetPasswordState copyWith({
    ResetPasswordStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ResetPasswordState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResetPasswordState &&
        other.status == status &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => status.hashCode ^ errorMessage.hashCode;
}
