import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/exceptions/captain_auth_exceptions.dart';
import '../../domain/usecases/clear_remembered_phone_usecase.dart';
import '../../domain/usecases/get_remembered_phone_usecase.dart';
import '../../domain/usecases/save_remembered_phone_usecase.dart';
import '../../domain/usecases/sign_in_captain_usecase.dart';
import '../../domain/usecases/sign_out_captain_usecase.dart';

sealed class CaptainAuthState {
  const CaptainAuthState();
}

class CaptainAuthIdle extends CaptainAuthState {
  const CaptainAuthIdle();
}

class CaptainAuthLoading extends CaptainAuthState {
  const CaptainAuthLoading();
}

class CaptainAuthSuccess extends CaptainAuthState {
  const CaptainAuthSuccess();
}

class CaptainAuthError extends CaptainAuthState {
  const CaptainAuthError(this.message);

  final String message;
}

class CaptainAuthCubit extends Cubit<CaptainAuthState> {
  CaptainAuthCubit({
    required SignInCaptainUseCase signIn,
    required SignOutCaptainUseCase signOut,
    required SaveRememberedPhoneUseCase saveRememberedPhone,
    required GetRememberedPhoneUseCase getRememberedPhone,
    required ClearRememberedPhoneUseCase clearRememberedPhone,
  }) : _signIn = signIn,
       _signOut = signOut,
       _saveRememberedPhone = saveRememberedPhone,
       _getRememberedPhone = getRememberedPhone,
       _clearRememberedPhone = clearRememberedPhone,
       super(const CaptainAuthIdle());

  final SignInCaptainUseCase _signIn;
  final SignOutCaptainUseCase _signOut;
  final SaveRememberedPhoneUseCase _saveRememberedPhone;
  final GetRememberedPhoneUseCase _getRememberedPhone;
  final ClearRememberedPhoneUseCase _clearRememberedPhone;

  /// Prefills the login form: reads whatever "Remember Me" previously saved.
  /// A read failure must render as "nothing remembered" rather than block
  /// the login screen from opening.
  Future<String?> loadRememberedPhone() async {
    try {
      return await _getRememberedPhone();
    } catch (_) {
      return null;
    }
  }

  Future<void> signIn({required String phone, required bool rememberMe}) async {
    emit(const CaptainAuthLoading());
    try {
      await _signIn(phone: phone);
      await _applyRememberMe(rememberMe, phone: phone);
      if (!isClosed) emit(const CaptainAuthSuccess());
    } on CaptainPhoneNotRegisteredException {
      if (!isClosed) {
        emit(
          const CaptainAuthError(
            'هذا الرقم غير مسجّل كسائق نشط. تحقّق من الرقم أو اطلب الانضمام.',
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          CaptainAuthError(
            error.toString().replaceFirst(RegExp(r'^Exception: ?'), ''),
          ),
        );
      }
    }
  }

  /// Signing out must always land the captain back at idle. The local identity
  /// is cleared by the datasource either way, so a network failure in Supabase's
  /// sign-out is not something to strand the captain on a half-signed-out screen
  /// over — reporting it would offer them no action but to try again.
  Future<void> signOut() async {
    try {
      await _signOut();
    } catch (_) {
    } finally {
      if (!isClosed) emit(const CaptainAuthIdle());
    }
  }

  /// Persisting (or clearing) the remembered phone is a device-storage
  /// side-effect, not part of authentication proper — a write failure here
  /// must never turn a successful sign-in into a reported failure.
  Future<void> _applyRememberMe(bool rememberMe, {required String phone}) async {
    try {
      if (rememberMe) {
        await _saveRememberedPhone(phone);
      } else {
        await _clearRememberedPhone();
      }
    } catch (_) {}
  }

  void resetError() {
    if (state is CaptainAuthError) emit(const CaptainAuthIdle());
  }
}
