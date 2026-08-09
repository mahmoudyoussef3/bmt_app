import '../models/social_auth_result_model.dart';

/// Talks to the identity providers (Google, Apple).
///
/// Mirrors [ClientAuthDatasource]'s shape — an abstract contract with a
/// Supabase implementation behind it — so the real implementation lands as a
/// sibling file (`supabase_social_auth_datasource.dart`) and nothing above it
/// changes.
abstract class SocialAuthDatasource {
  Future<SocialAuthResultModel> signInWithGoogle();

  Future<SocialAuthResultModel> signInWithApple();
}
