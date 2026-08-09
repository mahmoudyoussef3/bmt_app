import '../../domain/entities/auth_method.dart';
import '../../domain/entities/auth_method_failure.dart';
import '../models/social_auth_result_model.dart';
import 'social_auth_datasource.dart';

/// The [SocialAuthDatasource] this build ships with: no provider is configured,
/// so every call fails as [AuthMethodFailure.unavailable].
///
/// It exists so the graph above it is real — repository, use cases, cubit and
/// DI are all wired to a live object today, and turning Google or Apple on is a
/// one-line swap in `client_di.dart` plus a flag in [AuthMethod], with no new
/// plumbing.
///
/// Nothing reaches this class in normal use: the provider buttons are inert
/// while [AuthMethod.isAvailable] is false, and [SocialAuthCubit] refuses the
/// call before it gets here. Throwing rather than returning a fake result is
/// the point — a stub that invented a `SocialAuthResult` would hand the app a
/// session that does not exist.
///
/// The real implementation belongs in `supabase_social_auth_datasource.dart`
/// and needs, per provider:
/// - **Google** — `signInWithOAuth(OAuthProvider.google)` (or the native
///   `google_sign_in` id-token flow), plus the Web/iOS/Android client IDs in
///   the Supabase Auth provider settings and the reversed-client-id URL scheme
///   in `ios/Runner/Info.plist`.
/// - **Apple** — `signInWithApple()` behind the Sign in with Apple capability,
///   a Services ID + key in Supabase, and storage of the full name on the very
///   first consent (Apple never sends it twice).
///
/// Both must classify their failures into [AuthMethodFailure] — in particular a
/// dismissed provider sheet is `cancelled`, not `unknown`.
class PendingSocialAuthDatasource implements SocialAuthDatasource {
  const PendingSocialAuthDatasource();

  @override
  Future<SocialAuthResultModel> signInWithGoogle() =>
      throw const AuthMethodException(
        AuthMethodFailure.unavailable,
        method: AuthMethod.google,
        details: 'Google sign-in is not configured in this build.',
      );

  @override
  Future<SocialAuthResultModel> signInWithApple() =>
      throw const AuthMethodException(
        AuthMethodFailure.unavailable,
        method: AuthMethod.apple,
        details: 'Apple sign-in is not configured in this build.',
      );
}
