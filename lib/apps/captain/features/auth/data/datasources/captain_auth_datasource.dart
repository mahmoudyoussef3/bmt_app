import 'package:supabase_flutter/supabase_flutter.dart';

class CaptainAuthDatasource {
  const CaptainAuthDatasource(this._supabase);

  final SupabaseClient _supabase;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception(_authMessage(e));
    } catch (_) {
      throw Exception('Sign in failed. Check your connection and try again.');
    }
  }

  Future<bool> isActiveDriver() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final driver = await _supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle();
    return driver != null;
  }

  Future<void> signOut() => _supabase.auth.signOut();

  String _authMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('rate') || message.contains('seconds')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return 'Could not sign in. Please try again.';
  }
}
