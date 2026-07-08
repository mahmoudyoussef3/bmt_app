import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/exceptions/captain_auth_exceptions.dart';

/// Passwordless captain login: the phone is checked server-side against
/// active drivers (resolve_captain_login), which hands back a stable
/// email/secret pair derived from that phone. We sign in with it — or sign
/// up, the first time a phone is seen — then bind the resulting session to
/// the driver record via link_current_captain_driver.
class CaptainAuthDatasource {
  const CaptainAuthDatasource(this._supabase);

  final SupabaseClient _supabase;

  Future<void> signInWithPhone(String phone) async {
    final resolved = await _supabase.rpc(
      'resolve_captain_login',
      params: {'p_phone': phone},
    );
    final map = Map<String, dynamic>.from(resolved as Map);
    if (map['outcome'] != 'ready') {
      throw CaptainPhoneNotRegisteredException();
    }

    final email = map['login_email'] as String;
    final secret = map['login_secret'] as String;

    try {
      await _supabase.auth.signInWithPassword(email: email, password: secret);
    } on AuthException catch (e) {
      if (!_isInvalidCredentials(e)) throw Exception(_authMessage(e));
      try {
        await _supabase.auth.signUp(
          email: email,
          password: secret,
          data: {
            'full_name': map['full_name'],
            'employee_code': map['employee_code'],
            'role': 'driver',
          },
        );
      } on AuthException catch (signUpError) {
        throw Exception(_authMessage(signUpError));
      }
    }

    await _supabase.rpc(
      'link_current_captain_driver',
      params: {'p_phone': phone},
    );
  }

  Future<void> signOut() => _supabase.auth.signOut();

  bool _isInvalidCredentials(AuthException e) =>
      e.message.toLowerCase().contains('invalid login credentials');

  String _authMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('rate') || message.contains('seconds')) {
      return 'محاولات كثيرة، حاول مرة أخرى بعد قليل.';
    }
    return 'تعذّر تسجيل الدخول، حاول مرة أخرى.';
  }
}
