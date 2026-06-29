import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardAuthDatasource {
  const DashboardAuthDatasource(this._supabase);

  final SupabaseClient _supabase;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('فشل تسجيل الدخول. تحقق من بياناتك.');
    }
  }

  /// Returns true only if the signed-in user has a dashboard role
  /// (dashboard_admin or support_agent) in the user_roles table.
  Future<bool> isDashboardUser() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return false;

    try {
      final rows = await _supabase
          .from('user_roles')
          .select('role')
          .eq('user_id', uid)
          .not('role', 'eq', 'client')
          .not('role', 'eq', 'driver')
          .limit(1);
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() => _supabase.auth.signOut();

  // Re-expose getCurrentUserRole so the shell can still use it
  Future<String?> getCurrentRole() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final rows = await _supabase
        .from('user_roles')
        .select('role')
        .eq('user_id', uid)
        .not('role', 'eq', 'client')
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['role'] as String?;
  }
}
