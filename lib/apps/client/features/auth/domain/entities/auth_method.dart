/// The ways a rider can get into their EasyWay account.
///
/// Email + password is the only method this build actually performs, so it is
/// not listed here: it needs no availability switch and it already has its own
/// repository, use cases and cubit. This enum covers the *alternative* methods
/// whose UI ships now and whose providers land later.
///
/// [isAvailable] is the single switch that turns a method on. Nothing else in
/// the app decides whether a provider is offerable — the buttons, the cubit and
/// the phone/OTP screens all read this flag — so wiring a provider is:
///
/// 1. implement its datasource (`data/datasources/`),
/// 2. register the real datasource in `client_di.dart` in place of the pending
///    one, and
/// 3. flip the flag here.
///
/// No UI has to be redesigned for that; the disabled state is a property of the
/// method, not a hard-coded look.
enum AuthMethod {
  google(isAvailable: false),
  apple(isAvailable: false),
  phoneOtp(isAvailable: false);

  const AuthMethod({required this.isAvailable});

  /// Whether the provider behind this method is wired up in this build.
  final bool isAvailable;
}
