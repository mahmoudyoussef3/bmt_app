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
      throw Exception('فشل تسجيل الدخول. تحقق من البيانات وأعد المحاولة.');
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
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    }
    if (message.contains('rate') || message.contains('seconds')) {
      return 'محاولات كثيرة. انتظر قليلاً ثم أعد المحاولة.';
    }
    return 'تعذر تسجيل الدخول. حاول مرة أخرى.';
  }
}
