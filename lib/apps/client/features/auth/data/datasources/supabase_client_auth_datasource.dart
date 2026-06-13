import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/client_registration.dart';
import '../models/otp_request_model.dart';
import 'client_auth_datasource.dart';

class SupabaseClientAuthDatasource implements ClientAuthDatasource {
  final SupabaseClient _supabase;

  const SupabaseClientAuthDatasource(this._supabase);

  @override
  Future<OtpRequestModel> requestOtp({
    required String dialCode,
    required String phone,
  }) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8 || digits.length > 11) {
      throw const FormatException('Enter a valid mobile number (8–11 digits)');
    }
    
    final formattedPhone = '$dialCode${phone.trim()}'.replaceAll(' ', '').replaceAll('+', '');
    final phoneWithPlus = '+$formattedPhone';

    try {
      await _supabase.auth.signInWithOtp(phone: phoneWithPlus);
      return OtpRequestModel(formattedPhone: phoneWithPlus);
    } catch (e) {
      throw Exception('Failed to send OTP. Ensure SMS provider is configured in Supabase: $e');
    }
  }

  @override
  Future<void> verifyOtp({required String phone, required String code}) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: code,
        type: OtpType.sms,
      );
      if (response.session == null) {
        throw const FormatException('Invalid or expired OTP code.');
      }
    } catch (e) {
      throw const FormatException('Invalid code. Please try again or request a new code.');
    }
  }

  @override
  Future<void> register(ClientRegistration registration) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated. Please verify OTP first.');
    }

    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(registration.email.trim());
    if (registration.fullName.trim().length < 2 || !emailOk) {
      throw const FormatException('Complete the required profile fields correctly.');
    }

    try {
      // Upsert client profile details into the `clients` table
      await _supabase.from('clients').upsert({
        'id': user.id,
        'full_name': registration.fullName.trim(),
        'phone': registration.phone.trim(),
        'email': registration.email.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Unable to complete registration: $e');
    }
  }
}
