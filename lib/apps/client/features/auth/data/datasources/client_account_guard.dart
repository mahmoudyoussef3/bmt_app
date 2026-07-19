import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads and writes the `clients` table that backs client-app accounts. Kept
/// separate from [SupabaseClientAuthDatasource] so the Supabase auth calls stay
/// distinct from the profile-row bookkeeping around them.
class ClientAccountGuard {
  const ClientAccountGuard(this._supabase);

  final SupabaseClient _supabase;

  /// Ensures the signed-in user is registered as a client. If not, signs them
  /// out and throws so a wrong-app account can't proceed.
  Future<void> assertRegistered() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final row = await _supabase
        .from('clients')
        .select('id')
        .eq('id', uid)
        .maybeSingle();
    if (row == null) {
      await _supabase.auth.signOut();
      throw Exception(
        'This account is not registered as a client.\n'
        'Use the correct app for your account type.',
      );
    }
  }

  /// True when [phone] already belongs to a client. Fails open: a failed
  /// pre-check lets sign-up proceed rather than blocking on a false negative.
  Future<bool> phoneRegistered(String phone) async {
    try {
      final result = await _supabase.rpc(
        'check_phone_exists',
        params: {'p_phone': phone},
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Best-effort profile upsert. The backend trigger already inserts the row,
  /// so a failure here (e.g. RLS) must not fail the sign-up.
  Future<void> upsertProfile(
    User user, {
    required String fullName,
    required String phone,
    required String email,
  }) async {
    try {
      await _supabase.from('clients').upsert({
        'id': user.id,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}
