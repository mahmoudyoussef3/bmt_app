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
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Login failed. Please check your credentials.');
    }
  }

  @override
  Future<void> signUpWithEmail({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim());
    if (fullName.trim().length < 2 || !emailOk || phone.trim().isEmpty) {
      throw const FormatException('Please complete all fields correctly.');
    }

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone': phone.trim(),
        },
      );

      final user = response.user;
      if (user != null) {
        // Upsert client profile details into the `clients` table
        await _supabase.from('clients').upsert({
          'id': user.id,
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'email': email.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Unable to create account. Please try again later.');
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
