import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/captain_auth_datasource.dart';

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
  CaptainAuthCubit(this._datasource) : super(const CaptainAuthIdle());

  final CaptainAuthDatasource _datasource;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(const CaptainAuthLoading());
    try {
      await _datasource.signIn(email: email, password: password);

      final ok = await _datasource.isDriver();
      if (!ok) {
        await _datasource.signOut();
        emit(const CaptainAuthError(
          'هذا الحساب غير مسجل كسائق.\nتواصل مع المسؤول لإضافة حسابك.',
        ));
        return;
      }

      emit(const CaptainAuthSuccess());
    } catch (e) {
      emit(CaptainAuthError(
        e.toString().replaceFirst(RegExp(r'^Exception: ?'), ''),
      ));
    }
  }

  Future<void> signOut() async {
    await _datasource.signOut();
    emit(const CaptainAuthIdle());
  }

  void resetError() {
    if (state is CaptainAuthError) emit(const CaptainAuthIdle());
  }
}
