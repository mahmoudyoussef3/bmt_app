import '../../../../core/session/office_context.dart';

/// The dashboard's authentication boundary.
///
/// Every method that can fail throws [DashboardAuthFailure] carrying the
/// sentence to show; there is no result union here because the cubit has
/// exactly one thing to do with a failure and it is the same in all four cases.
abstract class DashboardAuthRepository {
  /// True when a cached Supabase session exists, so app start can try to restore
  /// rather than showing the login screen to someone already signed in.
  bool get hasCachedSession;

  /// Signs in with the operator's name (not their email) and returns the office
  /// they operate.
  Future<OfficeContext> signIn({
    required String username,
    required String password,
  });

  /// Registers a new office and signs its owner into it.
  Future<OfficeContext> signUp({
    required String email,
    required String password,
    required String officeName,
  });

  /// Re-reads the office context for the current session.
  Future<OfficeContext> loadContext();

  Future<void> signOut();
}
