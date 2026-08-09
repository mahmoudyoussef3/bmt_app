import '../entities/social_auth_result.dart';

/// Sign-in through an identity provider (Google, Apple).
///
/// Separate from [ClientAuthRepository] on purpose: that contract is about
/// credentials this app holds and verifies, this one is about handing the rider
/// to someone else and being told who came back. Folding them together would
/// force every email/password caller to depend on provider SDKs it never uses.
///
/// Implementations throw [AuthMethodException] and never return a null result —
/// "the rider closed the Google sheet" is [AuthMethodFailure.cancelled], not a
/// silent success with nothing in it.
abstract class SocialAuthRepository {
  Future<SocialAuthResult> signInWithGoogle();

  Future<SocialAuthResult> signInWithApple();
}
