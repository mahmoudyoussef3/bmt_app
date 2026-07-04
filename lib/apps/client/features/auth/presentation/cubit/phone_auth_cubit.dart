import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/network/api_result.dart';
import '../../domain/usecases/complete_profile_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/verify_phone_usecase.dart';
import 'phone_auth_state.dart';

class PhoneAuthCubit extends Cubit<PhoneAuthState> {
  final VerifyPhoneUseCase verifyPhoneUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final CompleteProfileUseCase completeProfileUseCase;

  PhoneAuthCubit({
    required this.verifyPhoneUseCase,
    required this.verifyOtpUseCase,
    required this.completeProfileUseCase,
  }) : super(AuthInitial());

  Future<void> submitPhone(String phone) async {
    emit(AuthLoading());
    final result = await verifyPhoneUseCase(phone);
    
    switch (result) {
      case Success():
        emit(AuthPhoneSubmitted(phone));
        break;
      case Failure(:final message):
        emit(AuthError(message));
        break;
    }
  }

  Future<void> submitOtp(String phone, String otp) async {
    emit(AuthLoading());
    final result = await verifyOtpUseCase(phone, otp);

    switch (result) {
      case Success(:final data):
        if (data != null) {
          emit(AuthAuthenticated(data));
        } else {
          emit(AuthProfileIncomplete(phone));
        }
        break;
      case Failure(:final message):
        emit(AuthError(message));
        emit(AuthPhoneSubmitted(phone)); // Reset to OTP screen
        break;
    }
  }

  Future<void> completeProfile({
    required String phone,
    required String fullName,
    String? email,
    String? gender,
    String? preferredPickupArea,
  }) async {
    emit(AuthLoading());
    final result = await completeProfileUseCase(
      phone: phone,
      fullName: fullName,
      email: email,
      gender: gender,
      preferredPickupArea: preferredPickupArea,
    );

    switch (result) {
      case Success(:final data):
        emit(AuthAuthenticated(data));
        break;
      case Failure(:final message):
        emit(AuthError(message));
        emit(AuthProfileIncomplete(phone)); // Keep them on profile screen
        break;
    }
  }
}
