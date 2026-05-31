import 'dart:async';
import 'package:bmt_app/features/auth/domain/repositories/auth_repository_interface.dart';

class MockAuthRepository implements IAuthRepository {
  @override
  Future<String> login(String username, String password) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 300));
    // Very simple mock: accept any non-empty username/password
    if (username.isNotEmpty && password.isNotEmpty) {
      final token = 'mock-token-${DateTime.now().millisecondsSinceEpoch}';
      return token;
    }
    throw Exception('Invalid credentials');
  }

  @override
  Future<void> logout(String token) async {
    await Future.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<bool> validateToken(String token) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return token.isNotEmpty && token.startsWith('mock-token-');
  }
}
