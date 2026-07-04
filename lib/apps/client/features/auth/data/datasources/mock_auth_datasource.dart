import 'dart:math';
import '../../domain/entities/user_profile.dart';

class MockAuthDatasource {
  final Map<String, UserProfile> _mockDatabase = {
    '+201000000000': const UserProfile(
      id: 'usr_123',
      phone: '+201000000000',
      fullName: 'Ahmed Hassan',
      isProfileComplete: true,
    ),
  };

  final Map<String, String> _otpSessions = {};

  Future<void> verifyPhone(String phoneNumber) async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate network error randomly (5% chance)
    if (Random().nextDouble() < 0.05) {
      throw Exception('Network timeout, please try again.');
    }

    _otpSessions[phoneNumber] = '123456'; // Static mock OTP for testing
  }

  Future<UserProfile?> verifyOtp(String phoneNumber, String otp) async {
    await Future.delayed(const Duration(seconds: 2));

    if (_otpSessions[phoneNumber] != otp && otp != '123456') {
      throw Exception('Invalid OTP code. Please check and try again.');
    }

    _otpSessions.remove(phoneNumber);

    if (_mockDatabase.containsKey(phoneNumber)) {
      return _mockDatabase[phoneNumber];
    }
    return null; // New user
  }

  Future<UserProfile> completeProfile({
    required String phone,
    required String fullName,
    String? email,
    String? gender,
    String? preferredPickupArea,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    
    final newUser = UserProfile(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      phone: phone,
      fullName: fullName,
      email: email,
      gender: gender,
      preferredPickupArea: preferredPickupArea,
      isProfileComplete: true,
    );
    
    _mockDatabase[phone] = newUser;
    return newUser;
  }

  Future<UserProfile> socialLogin(String provider) async {
    await Future.delayed(const Duration(seconds: 2));
    return UserProfile(
      id: 'usr_social_${DateTime.now().millisecondsSinceEpoch}',
      phone: '+201111111111',
      fullName: 'Social User ($provider)',
      isProfileComplete: true,
    );
  }
}
