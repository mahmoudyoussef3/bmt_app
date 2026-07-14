import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/sign_in_with_email_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_with_email_usecase.dart';
import 'auth_state.dart';

class ClientAuthCubit extends Cubit<ClientAuthState> {
  ClientAuthCubit({
    required SignInWithEmailUseCase signInWithEmail,
    required SignUpWithEmailUseCase signUpWithEmail,
    required SignOutUseCase signOut,
  }) : _signInWithEmail = signInWithEmail,
       _signUpWithEmail = signUpWithEmail,
       _signOut = signOut,
       super(const ClientAuthState());

  final SignInWithEmailUseCase _signInWithEmail;
  final SignUpWithEmailUseCase _signUpWithEmail;
  final SignOutUseCase _signOut;

  Future<void> signIn({required String email, required String password}) async {
    emit(
      state.copyWith(
        signInStatus: AuthSubmissionStatus.loading,
        clearSignInError: true,
      ),
    );
    try {
      await _signInWithEmail(email: email, password: password);
      emit(state.copyWith(signInStatus: AuthSubmissionStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          signInStatus: AuthSubmissionStatus.failure,
          signInError: _messageFor(error),
        ),
      );
    }
  }

  Future<void> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    emit(
      state.copyWith(
        signUpStatus: AuthSubmissionStatus.loading,
        clearSignUpError: true,
      ),
    );
    try {
      await _signUpWithEmail(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
        referralCode: referralCode,
      );
      emit(state.copyWith(signUpStatus: AuthSubmissionStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          signUpStatus: AuthSubmissionStatus.failure,
          signUpError: _messageFor(error),
        ),
      );
    }
  }

  /// Ends the session. The UI waits on [ClientAuthState.signOutStatus] before
  /// it resets the navigation stack, so the rider is never dropped on the
  /// welcome screen while they are in fact still signed in.
  Future<void> signOut() async {
    if (state.signOutStatus == AuthSubmissionStatus.loading) return;

    emit(
      state.copyWith(
        signOutStatus: AuthSubmissionStatus.loading,
        clearSignOutError: true,
      ),
    );
    try {
      await _signOut();
      emit(state.copyWith(signOutStatus: AuthSubmissionStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          signOutStatus: AuthSubmissionStatus.failure,
          signOutError: _messageFor(error),
        ),
      );
    }
  }

  void dismissSignInError() {
    if (state.signInStatus == AuthSubmissionStatus.failure) {
      emit(
        state.copyWith(
          signInStatus: AuthSubmissionStatus.initial,
          clearSignInError: true,
        ),
      );
    }
  }

  void dismissSignUpError() {
    if (state.signUpStatus == AuthSubmissionStatus.failure) {
      emit(
        state.copyWith(
          signUpStatus: AuthSubmissionStatus.initial,
          clearSignUpError: true,
        ),
      );
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) {
      return error.message;
    }
    return error.toString().replaceAll('Exception: ', '');
  }
}
