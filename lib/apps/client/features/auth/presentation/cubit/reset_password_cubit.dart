import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/usecases/update_password_usecase.dart';
import 'reset_password_state.dart';

/// Drives the "set a new password" screen reached from the emailed recovery
/// link (`easyway://reset-password/...`).
///
/// Supabase's own deep-link handling (`SupabaseAuth` inside `supabase_flutter`)
/// already listens for that link, exchanges its code for a session and fires
/// `AuthChangeEvent.passwordRecovery` once it is ready — this cubit only
/// waits for that session before letting the form submit, so a rider can
/// never call `updateUser` with nothing to attach it to.
class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit(this._updatePasswordUseCase)
    : super(const ResetPasswordState()) {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession != null) {
      emit(state.copyWith(status: ResetPasswordStatus.ready));
    } else {
      _authSub = auth.onAuthStateChange.listen(
        _onAuthStateChange,
        onError: _onAuthError,
      );
      
      _verifyTimeout = Timer(
        const Duration(seconds: 12),
        () => _onAuthError('TimedOut', StackTrace.empty),
      );
    }
  }

  final UpdatePasswordUseCase _updatePasswordUseCase;
  StreamSubscription<AuthState>? _authSub;
  Timer? _verifyTimeout;

  void _onAuthStateChange(AuthState data) {
    if (state.status != ResetPasswordStatus.verifying) return;
    if (data.event == AuthChangeEvent.passwordRecovery ||
        data.session != null) {
      _verifyTimeout?.cancel();
      emit(state.copyWith(status: ResetPasswordStatus.ready));
    }
  }

  void _onAuthError(Object error, StackTrace stackTrace) {
    if (state.status != ResetPasswordStatus.verifying) return;
    _verifyTimeout?.cancel();
    emit(
      state.copyWith(
        status: ResetPasswordStatus.linkInvalid,
        errorMessage: 'InvalidLink',
      ),
    );
  }

  Future<void> submit(String newPassword) async {
    if (state.status != ResetPasswordStatus.ready &&
        state.status != ResetPasswordStatus.failure) {
      return;
    }
    emit(
      state.copyWith(status: ResetPasswordStatus.loading, clearError: true),
    );
    try {
      await _updatePasswordUseCase(newPassword);
      
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      emit(state.copyWith(status: ResetPasswordStatus.success));
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      emit(
        state.copyWith(
          status: ResetPasswordStatus.failure,
          errorMessage: message,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _verifyTimeout?.cancel();
    _authSub?.cancel();
    return super.close();
  }
}
