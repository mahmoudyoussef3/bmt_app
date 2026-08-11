/// Answers whether the session the app is holding may be trusted as a
/// passenger's.
///
/// Separate from `ClientAuthRepository` on purpose: signing in is an action the
/// rider takes, while this vets a session that was already there when the app
/// started.
abstract class ClientSessionRepository {
  /// True when a restored session belongs to a registered client. A session
  /// that belongs to another EWT app's account is signed out first, so a false
  /// answer always leaves the app signed out.
  Future<bool> ensureClientSession();
}
