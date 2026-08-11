/// Named routes for the Client App authentication UI flow.
class AuthRoutes {
  AuthRoutes._();

  static const String welcome = '/auth/welcome';
  static const String signIn = '/auth/sign-in';
  static const String signUp = '/auth/sign-up';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String success = '/auth/success';

  static const String phoneLogin = '/auth/phone';
  static const String otpVerification = '/auth/phone/verify';
}
