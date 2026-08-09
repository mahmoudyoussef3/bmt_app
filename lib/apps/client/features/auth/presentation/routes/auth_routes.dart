/// Named routes for the Client App authentication UI flow.
class AuthRoutes {
  AuthRoutes._();

  static const String welcome = '/auth/welcome';
  static const String signIn = '/auth/sign-in';
  static const String signUp = '/auth/sign-up';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String success = '/auth/success';

  // Passwordless sign-in by SMS. Two steps: the number, then the code.
  //
  // Registered and fully navigable, but with no live entry point — the provider
  // buttons that would open [phoneLogin] are inert while
  // `AuthMethod.phoneOtp.isAvailable` is false. That flag is the only thing
  // standing between these screens and a rider; the routes exist now so turning
  // it on needs no routing work.
  static const String phoneLogin = '/auth/phone';
  static const String otpVerification = '/auth/phone/verify';
}
