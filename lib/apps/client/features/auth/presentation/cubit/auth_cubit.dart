import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/client_registration.dart';
import '../../domain/usecases/register_client_usecase.dart';
import '../../domain/usecases/request_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'auth_state.dart';

class ClientAuthCubit extends Cubit<ClientAuthState> {
  ClientAuthCubit({
    required RequestOtpUseCase requestOtp,
    required VerifyOtpUseCase verifyOtp,
    required RegisterClientUseCase registerClient,
  }) : _requestOtp = requestOtp,
       _verifyOtp = verifyOtp,
       _registerClient = registerClient,
       super(const ClientAuthState());

  final RequestOtpUseCase _requestOtp;
  final VerifyOtpUseCase _verifyOtp;
  final RegisterClientUseCase _registerClient;

  Future<void> requestOtp({
    required String dialCode,
    required String phone,
  }) async {
    emit(
      state.copyWith(
        phoneStatus: AuthSubmissionStatus.loading,
        clearPhoneError: true,
      ),
    );
    try {
      final result = await _requestOtp(dialCode: dialCode, phone: phone);
      emit(
        state.copyWith(
          phoneStatus: AuthSubmissionStatus.success,
          formattedPhone: result.formattedPhone,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          phoneStatus: AuthSubmissionStatus.failure,
          phoneError: _messageFor(error),
        ),
      );
    }
  }

  Future<void> verifyOtp({required String phone, required String code}) async {
    emit(
      state.copyWith(
        otpStatus: AuthSubmissionStatus.loading,
        clearOtpError: true,
      ),
    );
    try {
      await _verifyOtp(phone: phone, code: code);
      emit(state.copyWith(otpStatus: AuthSubmissionStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          otpStatus: AuthSubmissionStatus.failure,
          otpError: _messageFor(error),
        ),
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    String? viaSocial,
  }) async {
    emit(
      state.copyWith(
        registrationStatus: AuthSubmissionStatus.loading,
        clearRegistrationError: true,
      ),
    );
    try {
      await _registerClient(
        ClientRegistration(
          fullName: fullName,
          email: email,
          phone: phone,
          viaSocial: viaSocial,
        ),
      );
      emit(state.copyWith(registrationStatus: AuthSubmissionStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          registrationStatus: AuthSubmissionStatus.failure,
          registrationError: _messageFor(error),
        ),
      );
    }
  }

  void resetOtpInput() {
    emit(
      state.copyWith(
        otpStatus: AuthSubmissionStatus.initial,
        clearOtpError: true,
      ),
    );
  }

  String _messageFor(Object error) {
    if (error is FormatException) {
      return error.message;
    }
    return error.toString();
  }
}
