import '../../../../../../core/network/api_result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/mock_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final MockAuthDatasource datasource;

  AuthRepositoryImpl(this.datasource);

  @override
  Future<ApiResult<void>> verifyPhone(String phoneNumber) async {
    try {
      await datasource.verifyPhone(phoneNumber);
      return const Success(null);
    } catch (e) {
      return Failure(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<ApiResult<UserProfile?>> verifyOtp(String phoneNumber, String otp) async {
    try {
      final user = await datasource.verifyOtp(phoneNumber, otp);
      return Success(user);
    } catch (e) {
      return Failure(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<ApiResult<UserProfile>> completeProfile({
    required String phone,
    required String fullName,
    String? email,
    String? gender,
    String? preferredPickupArea,
  }) async {
    try {
      final user = await datasource.completeProfile(
        phone: phone,
        fullName: fullName,
        email: email,
        gender: gender,
        preferredPickupArea: preferredPickupArea,
      );
      return Success(user);
    } catch (e) {
      return Failure(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<ApiResult<UserProfile>> socialLogin(String provider) async {
    try {
      final user = await datasource.socialLogin(provider);
      return Success(user);
    } catch (e) {
      return Failure(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<ApiResult<void>> logout() async {
    return const Success(null);
  }
}
