import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/dashboard_session.dart';
import '../../../../core/session/office_context.dart';
import '../../data/datasources/dashboard_auth_datasource.dart';

sealed class DashboardAuthState {
  const DashboardAuthState();
}

/// App start, before we know whether a cached session exists.
class DashboardAuthChecking extends DashboardAuthState {
  const DashboardAuthChecking();
}

class DashboardAuthSignedOut extends DashboardAuthState {
  const DashboardAuthSignedOut();
}

class DashboardAuthLoading extends DashboardAuthState {
  const DashboardAuthLoading();
}

class DashboardAuthSignedIn extends DashboardAuthState {
  const DashboardAuthSignedIn(this.context);
  final OfficeContext context;
}

class DashboardAuthError extends DashboardAuthState {
  const DashboardAuthError(this.message);
  final String message;
}

/// Owns the dashboard's authentication lifecycle and keeps [DashboardSession] in step
/// with it. Registered as a singleton so the auth gate and the sign-out button act on
/// the same instance — the previous factory registration meant signing out constructed
/// a throwaway cubit whose state nobody observed.
class DashboardAuthCubit extends Cubit<DashboardAuthState> {
  DashboardAuthCubit(this._datasource, this._session)
    : super(const DashboardAuthChecking());

  final DashboardAuthDatasource _datasource;
  final DashboardSession _session;

  /// Restores a cached Supabase session on app start, so a reload does not force a
  /// re-login. Falls back to signed-out if the office context can no longer be loaded
  /// (account disabled, office suspended, operator moved).
  Future<void> restore() async {
    if (!_datasource.hasCachedSession) {
      emit(const DashboardAuthSignedOut());
      return;
    }
    emit(const DashboardAuthChecking());
    try {
      final context = await _datasource.loadContext();
      _session.start(context);
      emit(DashboardAuthSignedIn(context));
    } catch (_) {
      await _datasource.signOut();
      _session.clear();
      emit(const DashboardAuthSignedOut());
    }
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    emit(const DashboardAuthLoading());
    try {
      final context = await _datasource.signIn(
        username: username,
        password: password,
      );
      _session.start(context);
      emit(DashboardAuthSignedIn(context));
    } on DashboardAuthFailure catch (e) {
      _session.clear();
      emit(DashboardAuthError(e.message));
    } catch (_) {
      _session.clear();
      emit(const DashboardAuthError('تعذر تسجيل الدخول. حاول مرة أخرى.'));
    }
  }

  Future<void> signOut() async {
    await _datasource.signOut();
    _session.clear();
    emit(const DashboardAuthSignedOut());
  }

  void resetError() {
    if (state is DashboardAuthError) emit(const DashboardAuthSignedOut());
  }
}
