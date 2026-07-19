import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/remembered_credentials.dart';
import '../../domain/usecases/sign_in_with_email_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_with_email_usecase.dart';
import 'auth_error_message.dart';
import 'auth_state.dart';
import 'remember_me_coordinator.dart';

/// Drives the email/password auth flows (sign-in, sign-up, sign-out) plus the
/// "Remember Me" prefill. Each flow reports through its own status field so the
/// sign-in, sign-up and profile screens observe only what concerns them.
class ClientAuthCubit extends Cubit<ClientAuthState> {
  ClientAuthCubit({
    required SignInWithEmailUseCase signInWithEmail,
    required SignUpWithEmailUseCase signUpWithEmail,
    required SignOutUseCase signOut,
    required RememberMeCoordinator rememberMe,
  }) : _signInWithEmail = signInWithEmail,
       _signUpWithEmail = signUpWithEmail,
       _signOut = signOut,
       _rememberMe = rememberMe,
       super(const ClientAuthState());

  final SignInWithEmailUseCase _signInWithEmail;
  final SignUpWithEmailUseCase _signUpWithEmail;
  final SignOutUseCase _signOut;
  final RememberMeCoordinator _rememberMe;

  /// Prefills the login form with whatever "Remember Me" previously saved.
  Future<RememberedCredentials?> loadRememberedCredentials() =>
      _rememberMe.load();

  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    emit(state.signInLoading());
    try {
      await _signInWithEmail(email: email, password: password);
      await _rememberMe.apply(rememberMe, email: email, password: password);
      emit(state.copyWith(signInStatus: AuthSubmissionStatus.success));
    } catch (error) {
      emit(state.signInFailure(authErrorMessage(error)));
    }
  }

  Future<void> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    emit(state.signUpLoading());
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
      emit(state.signUpFailure(authErrorMessage(error)));
    }
  }

  /// Ends the session. The profile hub waits on [ClientAuthState.signOutStatus]
  /// before it resets navigation, so the rider is never dropped on the welcome
  /// screen while still signed in.
  Future<void> signOut() async {
    if (state.signOutStatus == AuthSubmissionStatus.loading) return;
    emit(state.signOutLoading());
    try {
      await _signOut();
      emit(state.copyWith(signOutStatus: AuthSubmissionStatus.success));
    } catch (error) {
      emit(state.signOutFailure(authErrorMessage(error)));
    }
  }

  void dismissSignInError() {
    if (state.signInStatus == AuthSubmissionStatus.failure) {
      emit(state.signInDismissed());
    }
  }

  void dismissSignUpError() {
    if (state.signUpStatus == AuthSubmissionStatus.failure) {
      emit(state.signUpDismissed());
    }
  }
}
