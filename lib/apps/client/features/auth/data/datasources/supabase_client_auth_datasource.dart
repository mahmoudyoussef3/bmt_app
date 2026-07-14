import 'package:supabase_flutter/supabase_flutter.dart';
import 'client_auth_datasource.dart';

class SupabaseClientAuthDatasource implements ClientAuthDatasource {
  final SupabaseClient _supabase;

  const SupabaseClientAuthDatasource(this._supabase);

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      // Surface the real reason (e.g. invalid credentials, email not
      // confirmed) instead of a blanket message the user can't act on.
      throw Exception(e.message);
    }

    // Role guard: only users registered as clients may use this app.
    final uid = _supabase.auth.currentUser?.id;
    if (uid != null) {
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
  }

  @override
  Future<void> signUpWithEmail({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim());
    if (fullName.trim().length < 2 || !emailOk || phone.trim().isEmpty) {
      throw const FormatException('Please complete all fields correctly.');
    }

    final phone_ = phone.trim();
    final code = referralCode?.trim().toUpperCase() ?? '';

    // Guard the phone UNIQUE constraint up front so a duplicate produces a
    // clear, actionable message rather than an opaque trigger error. This
    // check is thrown OUTSIDE the sign-up try/catch so its message survives.
    if (await _phoneAlreadyRegistered(phone_)) {
      throw Exception(
        'This phone number is already registered.\n'
        'Please sign in instead, or use a different number.',
      );
    }

    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone': phone_,
          // Captured here so the backend trigger can record a pending referral
          // against this code once the account is created.
          if (code.isNotEmpty) 'referral_code': code,
        },
      );

      final user = response.user;
      if (user != null) {
        // Best-effort profile upsert; the backend trigger already inserts the
        // row, so a failure here (e.g. RLS) does not fail the sign-up.
        try {
          await _supabase.from('clients').upsert({
            'id': user.id,
            'full_name': fullName.trim(),
            'phone': phone_,
            'email': email.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }
    } on AuthException catch (e) {
      // e.g. "User already registered" — surface it so the user can react.
      throw Exception(e.message);
    }
  }

  /// Returns true when [phone] already belongs to a client. Fails open: if the
  /// pre-check itself errors, sign-up still proceeds and any real failure is
  /// surfaced by [signUpWithEmail] instead of being swallowed here.
  Future<bool> _phoneAlreadyRegistered(String phone) async {
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

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // A global sign-out needs the network to revoke the refresh token. When
      // that call fails the rider is still holding a valid local session, so
      // fall back to a local sign-out: leaving them signed in on a device they
      // asked to sign out of is the worse outcome.
      await _supabase.auth.signOut(scope: SignOutScope.local);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim());
    if (!emailOk) {
      throw const FormatException('Please provide a valid email address.');
    }

    try {
      // Note: redirectTo should be configured based on your app's deep link setup.
      // E.g., 'bmtapp://reset-password/' or a universal link.
      // Here we provide a dummy default that the developer should configure in Supabase dashboard.
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'easyway://reset-password/',
      );
    } on AuthException catch (e) {
      // Map common Supabase errors like rate limit to generic messages
      if (e.message.contains('rate limit') ||
          e.message.contains('security purposes')) {
        throw Exception('RateLimit');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Unable to send reset link. Please try again later.');
    }
  }
}
