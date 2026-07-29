import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/core/validation/contact_validation.dart';

import 'client_account_guard.dart';
import 'client_auth_datasource.dart';

/// Supabase-backed auth for the client app. Delegates all `clients`-table
/// bookkeeping (role guard, phone check, profile sync) to [ClientAccountGuard].
class SupabaseClientAuthDatasource implements ClientAuthDatasource {
  SupabaseClientAuthDatasource(this._supabase)
    : _accounts = ClientAccountGuard(_supabase);

  final SupabaseClient _supabase;
  final ClientAccountGuard _accounts;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      // Surface the real reason (bad credentials, unconfirmed email) instead of
      // a blanket message the user can't act on.
      throw Exception(e.message);
    }
    // Only users registered as clients may use this app.
    await _accounts.assertRegistered();
  }

  @override
  Future<void> signUpWithEmail({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final trimmedPhone = phone.trim();
    if (fullName.trim().length < 2 ||
        !ContactValidation.isValidEmail(email) ||
        trimmedPhone.isEmpty) {
      throw const FormatException('Please complete all fields correctly.');
    }
    final code = referralCode?.trim().toUpperCase() ?? '';

    // Guard the phone UNIQUE constraint up front, outside the sign-up try/catch,
    // so a duplicate produces a clear message rather than an opaque trigger error.
    if (await _accounts.phoneRegistered(trimmedPhone)) {
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
          'phone': trimmedPhone,
          if (code.isNotEmpty) 'referral_code': code,
        },
      );
      final user = response.user;
      if (user != null) {
        await _accounts.upsertProfile(
          user,
          fullName: fullName.trim(),
          phone: trimmedPhone,
          email: email.trim(),
        );
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // A global sign-out needs the network to revoke the refresh token. When
      // that fails, fall back to a local sign-out rather than leaving the rider
      // signed in on a device they asked to sign out of.
      await _supabase.auth.signOut(scope: SignOutScope.local);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (!ContactValidation.isValidEmail(email)) {
      throw const FormatException('Please provide a valid email address.');
    }
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'easyway://reset-password/',
      );
    } on AuthException catch (e) {
      if (e.message.contains('rate limit') ||
          e.message.contains('security purposes')) {
        throw Exception('RateLimit');
      }
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Unable to send reset link. Please try again later.');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    if (newPassword.length < 6) {
      throw const FormatException(
        'Password must be at least 6 characters.',
      );
    }
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Unable to update password. Please try again later.');
    }
  }
}
