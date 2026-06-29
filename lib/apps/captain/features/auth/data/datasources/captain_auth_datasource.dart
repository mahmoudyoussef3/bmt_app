import 'package:supabase_flutter/supabase_flutter.dart';

class CaptainAuthDatasource {
  const CaptainAuthDatasource(this._supabase);

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
      throw Exception('فشل تسجيل الدخول. تحقق من البيانات وأعد المحاولة.');
    }
  }

  /// Returns true only if the signed-in user is a row in the drivers table.
  /// Tries auth-user-id first, then phone as fallback for manually-created accounts.
  Future<bool> isDriver() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final direct = await _supabase
        .from('drivers')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (direct != null) return true;

    final phone =
        user.phone ?? user.userMetadata?['phone']?.toString() ?? '';
    if (phone.isEmpty) return false;

    final byPhone = await _supabase
        .from('drivers')
        .select('id')
        .eq('phone', phone)
        .maybeSingle();
    return byPhone != null;
  }

  Future<void> signOut() => _supabase.auth.signOut();
}
