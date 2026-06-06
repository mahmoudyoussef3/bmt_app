enum AuthSubmissionStatus { initial, loading, success, failure }

class ClientAuthState {
  const ClientAuthState({
    this.phoneStatus = AuthSubmissionStatus.initial,
    this.otpStatus = AuthSubmissionStatus.initial,
    this.registrationStatus = AuthSubmissionStatus.initial,
    this.phoneError,
    this.otpError,
    this.registrationError,
    this.formattedPhone,
  });

  final AuthSubmissionStatus phoneStatus;
  final AuthSubmissionStatus otpStatus;
  final AuthSubmissionStatus registrationStatus;
  final String? phoneError;
  final String? otpError;
  final String? registrationError;
  final String? formattedPhone;

  ClientAuthState copyWith({
    AuthSubmissionStatus? phoneStatus,
    AuthSubmissionStatus? otpStatus,
    AuthSubmissionStatus? registrationStatus,
    String? phoneError,
    String? otpError,
    String? registrationError,
    String? formattedPhone,
    bool clearPhoneError = false,
    bool clearOtpError = false,
    bool clearRegistrationError = false,
  }) {
    return ClientAuthState(
      phoneStatus: phoneStatus ?? this.phoneStatus,
      otpStatus: otpStatus ?? this.otpStatus,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      phoneError: clearPhoneError ? null : phoneError ?? this.phoneError,
      otpError: clearOtpError ? null : otpError ?? this.otpError,
      registrationError: clearRegistrationError
          ? null
          : registrationError ?? this.registrationError,
      formattedPhone: formattedPhone ?? this.formattedPhone,
    );
  }
}
