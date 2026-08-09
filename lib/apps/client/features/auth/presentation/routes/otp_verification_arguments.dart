/// Arguments for `AuthRoutes.otpVerification`.
///
/// The OTP screen is reached by a named route, and a named route cannot carry a
/// cubit across the push — so the challenge that the phone screen obtained
/// travels as data instead. These four fields *are* an `OtpChallenge`,
/// flattened: the number the code went to, how many digits to draw, and the two
/// waits the screen counts down.
///
/// Only [phone] is genuinely required. The rest have provider-shaped defaults
/// so the screen is renderable before any provider exists; once one is wired
/// up, the real `OtpChallenge` supplies them and the defaults stop being used.
class OtpVerificationArguments {
  const OtpVerificationArguments({
    required this.phone,
    this.codeLength = 6,
    this.expiresInSeconds = 300,
    this.resendAfterSeconds = 30,
  });

  factory OtpVerificationArguments.fromArguments(Object? arguments) {
    final map = arguments is Map ? arguments : const {};
    int number(Object? value, int fallback) =>
        int.tryParse(value?.toString() ?? '') ?? fallback;

    return OtpVerificationArguments(
      phone: map['phone']?.toString() ?? '',
      codeLength: number(map['codeLength'], 6),
      expiresInSeconds: number(map['expiresInSeconds'], 300),
      resendAfterSeconds: number(map['resendAfterSeconds'], 30),
    );
  }

  /// E.164, as `ContactValidation.normalizeEgyptianPhone` produces it.
  final String phone;

  final int codeLength;
  final int expiresInSeconds;
  final int resendAfterSeconds;

  Map<String, Object?> toArguments() => {
    'phone': phone,
    'codeLength': codeLength,
    'expiresInSeconds': expiresInSeconds,
    'resendAfterSeconds': resendAfterSeconds,
  };

  bool get isValid => phone.isNotEmpty && codeLength > 0;

  /// `+20 10 1234 5678` — grouped for reading, never for sending.
  ///
  /// Carries no bidi control characters. A phone number rendered inside an
  /// Arabic sentence gets its `+` re-ordered to the wrong end by the bidi
  /// algorithm, so the screen puts this on its own line under a
  /// `TextDirection.ltr` — the same fix `edit_profile_sheet` and the receipt
  /// screen use — rather than smuggling isolates into the string.
  String get displayPhone {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!phone.startsWith('+20') || digits.length < 12) return phone;
    final national = digits.substring(2);
    return '+20 ${national.substring(0, 3)} ${national.substring(3, 7)} '
        '${national.substring(7)}';
  }
}
