import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entitlements/entitlement_service.dart';
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
  DashboardAuthCubit(this._datasource, this._session, [this._entitlements])
    : super(const DashboardAuthChecking());

  final DashboardAuthDatasource _datasource;
  final DashboardSession _session;

  /// Optional so a test can construct the cubit without a Supabase client.
  /// Absent, the shell simply falls back to [EntitlementContext.unknown], which
  /// allows everything — the same failing-open default the service itself uses.
  final EntitlementService? _entitlements;

  /// Sign-in is the one moment the entitlement document is guaranteed to be
  /// wanted, so it is loaded here rather than lazily by whoever needs it first.
  /// Deliberately not awaited: the console must render immediately, and every
  /// gate reads a permissive default until the answer arrives.
  void _startSession(OfficeContext context) {
    _session.start(context);
    unawaited(_entitlements?.load() ?? Future<void>.value());
  }

  void _clearSession() {
    _session.clear();
    _entitlements?.clear();
  }

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
      _startSession(context);
      emit(DashboardAuthSignedIn(context));
    } catch (_) {
      await _datasource.signOut();
      _clearSession();
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
      _startSession(context);
      emit(DashboardAuthSignedIn(context));
    } on DashboardAuthFailure catch (e) {
      _clearSession();
      emit(DashboardAuthError(e.message));
    } catch (_) {
      _clearSession();
      emit(const DashboardAuthError('تعذر تسجيل الدخول. حاول مرة أخرى.'));
    }
  }

  /// Registers a new office and signs its owner straight into it.
  ///
  /// Shares [DashboardAuthLoading] and [DashboardAuthError] with [signIn] rather than
  /// adding a parallel pair: the auth gate treats both screens the same way, and the
  /// sign-up screen is only ever mounted while the gate is in a signed-out state.
  Future<void> signUp({
    required String email,
    required String password,
    required String officeName,
  }) async {
    emit(const DashboardAuthLoading());
    try {
      final context = await _datasource.signUp(
        email: email,
        password: password,
        officeName: officeName,
      );
      _startSession(context);
      emit(DashboardAuthSignedIn(context));
    } on DashboardAuthFailure catch (e) {
      _clearSession();
      emit(DashboardAuthError(e.message));
    } catch (_) {
      _clearSession();
      emit(const DashboardAuthError('تعذر إنشاء الحساب. حاول مرة أخرى.'));
    }
  }

  /// Re-reads the office context for an already signed-in operator.
  ///
  /// Used after the office edits its own profile: the name and logo in the
  /// shell come from the context captured at sign-in, so without this they
  /// would stay stale until the next login. Deliberately never emits
  /// [DashboardAuthChecking] — that would tear the workspace down and drop the
  /// operator back to the home route mid-session. A failure is swallowed for
  /// the same reason: a refresh that could not run is not a reason to sign
  /// someone out of a session that is still valid.
  Future<void> refreshContext() async {
    if (state is! DashboardAuthSignedIn) return;
    try {
      final context = await _datasource.loadContext();
      _startSession(context);
      emit(DashboardAuthSignedIn(context));
    } catch (_) {
      // Keep the existing context.
    }
  }

  Future<void> signOut() async {
    await _datasource.signOut();
    _clearSession();
    emit(const DashboardAuthSignedOut());
  }

  void resetError() {
    if (state is DashboardAuthError) emit(const DashboardAuthSignedOut());
  }
}
