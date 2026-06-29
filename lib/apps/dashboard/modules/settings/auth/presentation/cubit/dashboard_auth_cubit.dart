import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/dashboard_auth_datasource.dart';

sealed class DashboardAuthState {
  const DashboardAuthState();
}

class DashboardAuthIdle extends DashboardAuthState {
  const DashboardAuthIdle();
}

class DashboardAuthLoading extends DashboardAuthState {
  const DashboardAuthLoading();
}

class DashboardAuthSuccess extends DashboardAuthState {
  const DashboardAuthSuccess();
}

class DashboardAuthError extends DashboardAuthState {
  const DashboardAuthError(this.message);
  final String message;
}

class DashboardAuthCubit extends Cubit<DashboardAuthState> {
  DashboardAuthCubit(this._datasource) : super(const DashboardAuthIdle());

  final DashboardAuthDatasource _datasource;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(const DashboardAuthLoading());
    try {
      await _datasource.signIn(email: email, password: password);

      final ok = await _datasource.isDashboardUser();
      if (!ok) {
        await _datasource.signOut();
        emit(const DashboardAuthError(
          'هذا الحساب لا يملك صلاحية الوصول للوحة التحكم.\nتواصل مع المسؤول لمنح الصلاحية.',
        ));
        return;
      }

      emit(const DashboardAuthSuccess());
    } catch (e) {
      emit(DashboardAuthError(
        e.toString().replaceFirst(RegExp(r'^Exception: ?'), ''),
      ));
    }
  }

  Future<void> signOut() async {
    await _datasource.signOut();
    emit(const DashboardAuthIdle());
  }

  void resetError() {
    if (state is DashboardAuthError) emit(const DashboardAuthIdle());
  }
}
