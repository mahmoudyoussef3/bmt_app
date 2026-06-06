import '../../domain/entities/client_registration.dart';
import '../../domain/entities/otp_request.dart';
import '../../domain/repositories/client_auth_repository.dart';
import '../datasources/mock_client_auth_datasource.dart';

class ClientAuthRepositoryImpl implements ClientAuthRepository {
  const ClientAuthRepositoryImpl(this._datasource);

  final MockClientAuthDatasource _datasource;

  @override
  Future<OtpRequest> requestOtp({
    required String dialCode,
    required String phone,
  }) async {
    try {
      final result = await _datasource.requestOtp(
        dialCode: dialCode,
        phone: phone,
      );
      return result.toEntity();
    } on FormatException {
      rethrow;
    } catch (error) {
      throw Exception('Unable to send code: $error');
    }
  }

  @override
  Future<void> verifyOtp({required String phone, required String code}) async {
    try {
      await _datasource.verifyOtp(phone: phone, code: code);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw Exception('Unable to verify code: $error');
    }
  }

  @override
  Future<void> register(ClientRegistration registration) async {
    try {
      await _datasource.register(registration);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw Exception('Unable to complete registration: $error');
    }
  }
}
