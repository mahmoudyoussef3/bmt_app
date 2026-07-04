import '../../../../../../core/network/api_result.dart';
import '../entities/user_profile.dart';

abstract class AuthRepository {
  Future<ApiResult<void>> verifyPhone(String phoneNumber);
  
  /// Returns a [UserProfile] if the user exists, or null if it's a new user requiring profile completion.
  Future<ApiResult<UserProfile?>> verifyOtp(String phoneNumber, String otp);
  
  Future<ApiResult<UserProfile>> completeProfile({
    required String phone,
    required String fullName,
    String? email,
    String? gender,
    String? preferredPickupArea,
  });
  
  Future<ApiResult<UserProfile>> socialLogin(String provider);
  
  Future<ApiResult<void>> logout();
}
