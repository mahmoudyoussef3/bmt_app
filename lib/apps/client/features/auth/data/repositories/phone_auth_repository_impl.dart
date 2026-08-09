import '../../domain/entities/auth_method.dart';
import '../../domain/entities/auth_method_failure.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/entities/social_auth_result.dart';
import '../../domain/repositories/phone_auth_repository.dart';
import '../datasources/phone_auth_datasource.dart';

class PhoneAuthRepositoryImpl implements PhoneAuthRepository {
  /// [now] is injectable because the OTP countdown is derived from it: the
  /// model reports "expires in N seconds" and only the moment the reply landed
  /// turns that into an instant a test can assert on.
  const PhoneAuthRepositoryImpl(
    this._datasource, {
    DateTime Function() now = DateTime.now,
  }) : _now = now;

  final PhoneAuthDatasource _datasource;
  final DateTime Function() _now;

  @override
  Future<OtpChallenge> sendOtp(String phone) async {
    try {
      final model = await _datasource.sendOtp(phone);
      return model.toEntity(sentAt: _now());
    } on AuthMethodException {
      rethrow;
    } catch (error) {
      throw AuthMethodException(
        AuthMethodFailure.unknown,
        method: AuthMethod.phoneOtp,
        details: error.toString(),
      );
    }
  }

  @override
  Future<SocialAuthResult> verifyOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final model = await _datasource.verifyOtp(phone: phone, code: code);
      return model.toEntity();
    } on AuthMethodException {
      rethrow;
    } catch (error) {
      throw AuthMethodException(
        AuthMethodFailure.unknown,
        method: AuthMethod.phoneOtp,
        details: error.toString(),
      );
    }
  }
}
