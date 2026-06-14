

enum ForgotPasswordStatus { initial, loading, success, failure }

class ForgotPasswordState {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.email = '',
    this.errorMessage,
    this.cooldownRemaining = 0,
  });

  final ForgotPasswordStatus status;
  final String email;
  final String? errorMessage;
  final int cooldownRemaining;

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? email,
    String? errorMessage,
    bool clearError = false,
    int? cooldownRemaining,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      email: email ?? this.email,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForgotPasswordState &&
        other.status == status &&
        other.email == email &&
        other.errorMessage == errorMessage &&
        other.cooldownRemaining == cooldownRemaining;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        email.hashCode ^
        errorMessage.hashCode ^
        cooldownRemaining.hashCode;
  }
}
