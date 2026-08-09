import 'auth_method.dart';

/// Why an alternative sign-in attempt did not produce a session.
///
/// A closed set rather than a message string: the client app is Arabic-first,
/// so the wording must come from the ARB catalogue at render time, and a
/// provider SDK's own English text ("popup_closed_by_user") is never something
/// to show a rider. The datasource classifies, the UI localizes.
enum AuthMethodFailure {
  /// The rider dismissed the provider sheet. Not an error to shout about — the
  /// UI clears back to the form.
  cancelled,

  /// The device could not reach the provider or the backend.
  network,

  /// The number typed is not a phone number we can send a code to.
  invalidPhone,

  /// The six digits entered do not match the code that was sent.
  invalidCode,

  /// The code was correct once but its window has closed; a new one is needed.
  expiredCode,

  /// Too many codes requested, or too many wrong attempts, in too short a time.
  rateLimited,

  /// The provider is not wired up in this build. Every alternative method
  /// reports this today — see [AuthMethod.isAvailable].
  unavailable,

  unknown,
}

/// The one exception the alternative-auth data layer throws.
///
/// The email/password repositories throw bare `Exception`s carrying a
/// user-facing English string ([authErrorMessage] unwraps them). That predates
/// localization; new code carries a [reason] instead so nothing user-facing has
/// to be assembled outside the widget tree.
class AuthMethodException implements Exception {
  const AuthMethodException(this.reason, {this.method, this.details});

  final AuthMethodFailure reason;

  /// Which method failed, when the thrower knows it.
  final AuthMethod? method;

  /// Provider/SDK text kept for logs only — never rendered.
  final String? details;

  @override
  String toString() =>
      'AuthMethodException(${reason.name}'
      '${method == null ? '' : ', ${method!.name}'}'
      '${details == null ? '' : ', $details'})';
}
