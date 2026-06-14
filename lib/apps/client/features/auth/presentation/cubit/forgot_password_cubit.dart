import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/send_password_reset_email_usecase.dart';
import 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit(this._sendPasswordResetEmailUseCase)
      : super(const ForgotPasswordState());

  final SendPasswordResetEmailUseCase _sendPasswordResetEmailUseCase;
  Timer? _cooldownTimer;

  void emailChanged(String email) {
    emit(state.copyWith(email: email, clearError: true));
  }

  Future<void> submitEmail() async {
    if (state.email.trim().isEmpty) return;
    if (state.status == ForgotPasswordStatus.loading) return;
    if (state.cooldownRemaining > 0) return;

    emit(
      state.copyWith(
        status: ForgotPasswordStatus.loading,
        clearError: true,
      ),
    );

    try {
      await _sendPasswordResetEmailUseCase(state.email.trim());
      emit(state.copyWith(status: ForgotPasswordStatus.success));
      _startCooldown();
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: message,
        ),
      );
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    emit(state.copyWith(cooldownRemaining: 60));
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.cooldownRemaining > 0) {
        emit(state.copyWith(cooldownRemaining: state.cooldownRemaining - 1));
      } else {
        timer.cancel();
      }
    });
  }

  void reset() {
    _cooldownTimer?.cancel();
    emit(const ForgotPasswordState());
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
