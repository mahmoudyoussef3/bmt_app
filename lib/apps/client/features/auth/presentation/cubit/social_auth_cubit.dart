import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_method.dart';
import '../../domain/entities/auth_method_failure.dart';
import '../../domain/usecases/send_phone_otp_usecase.dart';
import '../../domain/usecases/sign_in_with_apple_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/verify_phone_otp_usecase.dart';
import 'social_auth_state.dart';

/// Drives every sign-in method that is not email + password: Google, Apple and
/// phone/OTP.
///
/// Deliberately *not* part of [ClientAuthCubit]. That cubit owns the working
/// credential flows and the profile hub's sign-out; bolting three unbuilt
/// providers onto it would put churn into the one class a rider's ability to
/// sign in depends on. This is a sibling, provided per route by
/// `ClientCubitScopes.socialAuth`.
///
/// ## What runs today
///
/// Nothing reaches a provider. Every entry point starts with an
/// [AuthMethod.isAvailable] check and short-circuits to
/// [AuthMethodFailure.unavailable] while that flag is false, so no SDK is
/// touched, no code is sent and no session is created — the calls below are
/// safe to invoke, they simply refuse. The UI does not rely on that refusal:
/// the provider buttons are inert, so the guard is the second line of defence,
/// not the first.
///
/// The use cases behind it are fully wired to the pending datasources, which
/// throw the same `unavailable`. Turning a method on is therefore: implement
/// its datasource, register it in `client_di.dart`, flip the flag in
/// [AuthMethod]. No method body here changes.
class SocialAuthCubit extends Cubit<SocialAuthState> {
  SocialAuthCubit({
    required SignInWithGoogleUseCase signInWithGoogle,
    required SignInWithAppleUseCase signInWithApple,
    required SendPhoneOtpUseCase sendPhoneOtp,
    required VerifyPhoneOtpUseCase verifyPhoneOtp,
  }) : _signInWithGoogle = signInWithGoogle,
       _signInWithApple = signInWithApple,
       _sendPhoneOtp = sendPhoneOtp,
       _verifyPhoneOtp = verifyPhoneOtp,
       super(const SocialAuthState());

  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignInWithAppleUseCase _signInWithApple;
  final SendPhoneOtpUseCase _sendPhoneOtp;
  final VerifyPhoneOtpUseCase _verifyPhoneOtp;

  Future<void> signInWithGoogle() async {
    if (!_begin(AuthMethod.google)) return;
    await _guard(AuthMethod.google, () async {
      emit(state.succeeded(await _signInWithGoogle()));
    });
  }

  Future<void> signInWithApple() async {
    if (!_begin(AuthMethod.apple)) return;
    await _guard(AuthMethod.apple, () async {
      emit(state.succeeded(await _signInWithApple()));
    });
  }

  Future<void> sendOtp(String phone) async {
    if (!_begin(AuthMethod.phoneOtp)) return;
    await _guard(AuthMethod.phoneOtp, () async {
      emit(state.otpSent(await _sendPhoneOtp(phone)));
    });
  }

  /// Asks for a fresh code for the number already in [SocialAuthState.challenge].
  /// A no-op before one has been sent, so the resend button can call it without
  /// first proving a challenge exists.
  Future<void> resendOtp() async {
    final phone = state.challenge?.phone;
    if (phone == null) return;
    await sendOtp(phone);
  }

  Future<void> verifyOtp(String code) async {
    final challenge = state.challenge;
    if (challenge == null) return;
    if (!_begin(AuthMethod.phoneOtp)) return;
    await _guard(AuthMethod.phoneOtp, () async {
      emit(
        state.otpVerified(
          await _verifyPhoneOtp(
            phone: challenge.phone,
            code: code,
            codeLength: challenge.codeLength,
          ),
        ),
      );
    });
  }

  /// Drops the challenge so "change my number" returns to a clean phone screen
  /// instead of one still counting down towards a resend for the old number.
  void restartPhoneFlow() => emit(
    state.copyWith(
      status: SocialAuthStatus.initial,
      clearChallenge: true,
      clearFailure: true,
      clearResult: true,
    ),
  );

  void dismissError() {
    if (state.status == SocialAuthStatus.failed ||
        state.status == SocialAuthStatus.cancelled) {
      emit(state.errorDismissed());
    }
  }

  /// Emits `loading` and answers whether the caller may proceed.
  ///
  /// Returns false — after emitting the refusal — when the method is not
  /// enabled in this build, or when an attempt is already running. The second
  /// case matters as much as the first: a double tap on a provider button must
  /// not open two consent sheets.
  bool _begin(AuthMethod method) {
    if (state.isLoading) return false;
    if (!method.isAvailable) {
      emit(state.failed(method, AuthMethodFailure.unavailable));
      return false;
    }
    emit(state.loading(method));
    return true;
  }

  /// Runs [action], turning anything it throws into a typed failure.
  ///
  /// [AuthMethodFailure.cancelled] is routed to its own state rather than to
  /// `failed`: closing the Google sheet is a decision, not a fault, and must
  /// not raise a red banner.
  Future<void> _guard(AuthMethod method, Future<void> Function() action) async {
    try {
      await action();
    } on AuthMethodException catch (error) {
      emit(
        error.reason == AuthMethodFailure.cancelled
            ? state.cancelled(method)
            : state.failed(method, error.reason),
      );
    } catch (_) {
      emit(state.failed(method, AuthMethodFailure.unknown));
    }
  }
}
