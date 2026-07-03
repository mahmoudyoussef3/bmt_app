import 'package:flutter_bloc/flutter_bloc.dart';

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
  }) : _signIn = signIn,
       _signOut = signOut,
       super(const CaptainAuthIdle());

  final SignInCaptainUseCase _signIn;
  final SignOutCaptainUseCase _signOut;

  Future<void> signIn({required String email, required String password}) async {
    emit(const CaptainAuthLoading());
    try {
      await _signIn(email: email, password: password);
      if (!isClosed) emit(const CaptainAuthSuccess());
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

  Future<void> signOut() async {
    await _signOut();
    if (!isClosed) emit(const CaptainAuthIdle());
  }

  void resetError() {
    if (state is CaptainAuthError) emit(const CaptainAuthIdle());
  }
}
