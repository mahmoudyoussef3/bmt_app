import 'package:bmt_app/apps/dashboard/core/entitlements/licensing_failure.dart';
import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/staff_account.dart';
import '../../domain/usecases/create_dashboard_user_usecase.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/reset_dashboard_user_password_usecase.dart';
import '../../domain/usecases/set_dashboard_user_status_usecase.dart';
import '../../domain/usecases/update_user_role_usecase.dart';
import 'users_state.dart';

/// The office's staff directory and every action on it.
///
/// One rule shapes the whole class: **an action that fails never takes the list down
/// with it**. A refused role change or a rejected username emits [UsersActionFailure]
/// carrying the same list it started with, so the operator sees a message over the
/// directory they were working in rather than a full-screen error and a lost form.
class UsersCubit extends Cubit<UsersState> {
  UsersCubit({
    required GetUsersUseCase getUsers,
    required UpdateUserRoleUseCase updateRole,
    required CreateDashboardUserUseCase createUser,
    required ResetDashboardUserPasswordUseCase resetPassword,
    required SetDashboardUserStatusUseCase setStatus,
  }) : _getUsers = getUsers,
       _updateRole = updateRole,
       _createUser = createUser,
       _resetPassword = resetPassword,
       _setStatus = setStatus,
       super(const UsersLoading());

  final GetUsersUseCase _getUsers;
  final UpdateUserRoleUseCase _updateRole;
  final CreateDashboardUserUseCase _createUser;
  final ResetDashboardUserPasswordUseCase _resetPassword;
  final SetDashboardUserStatusUseCase _setStatus;

  /// The last list the cubit successfully held, whatever state it is currently in.
  ///
  /// Every action state carries the directory so the screen never blanks; this is the
  /// one place that knows how to find it.
  List<AppUser> get _users => switch (state) {
    UsersLoaded(:final users) => users,
    UsersActionSuccess(:final users) => users,
    UsersActionFailure(:final users) => users,
    UsersCredentialsIssued(:final users) => users,
    _ => const [],
  };

  Future<void> load() async {
    emit(const UsersLoading());
    try {
      emit(UsersLoaded(await _getUsers()));
    } catch (e) {
      emit(UsersError(_message(e)));
    }
  }

  /// Creates a login for a colleague and reveals the credentials once.
  ///
  /// Validates locally first so an obviously bad username never costs a round trip —
  /// and, more importantly, never reaches the Edge Function, which would create an auth
  /// user and then have to compensate for it.
  Future<void> createUser(StaffAccountRequest request) async {
    final users = _users;
    final errors = request.validate();
    if (errors.isNotEmpty) {
      emit(
        UsersActionFailure(
          'راجع البيانات المدخلة.',
          users,
          fieldErrors: errors,
        ),
      );
      return;
    }

    emit(UsersLoaded(users, isSubmitting: true));
    try {
      final credentials = await _createUser(request);
      // Refetched rather than appended: the row the server wrote carries the id,
      // timestamp and synthetic address only it knows. A locally assembled row would
      // be a guess at four fields, and the id is the one every later action names.
      emit(UsersCredentialsIssued(credentials, await _safeUsers(users)));
    } catch (e) {
      emit(UsersActionFailure(_message(e), users));
    }
  }

  /// Issues a new password for an existing account and reveals it once.
  Future<void> resetPassword(AppUser user, {String password = ''}) async {
    final users = _users;
    if (password.isNotEmpty && password.length < 10) {
      emit(
        UsersActionFailure(
          'كلمة المرور 10 أحرف على الأقل.',
          users,
          fieldErrors: const {'password': 'كلمة المرور 10 أحرف على الأقل'},
        ),
      );
      return;
    }

    emit(UsersLoaded(users, isSubmitting: true));
    try {
      final credentials = await _resetPassword(user.id, password: password);
      emit(UsersCredentialsIssued(credentials, users));
    } catch (e) {
      emit(UsersActionFailure(_message(e), users));
    }
  }

  Future<void> changeRole(String userRoleId, DashboardRole role) async {
    await _replaceRow(
      userRoleId,
      () => _updateRole(userRoleId, role),
      'تم تحديث الدور.',
    );
  }

  Future<void> setActive(AppUser user, {required bool active}) async {
    await _replaceRow(
      user.id,
      () => _setStatus(user.id, active: active),
      active ? 'تم تفعيل الحساب.' : 'تم تعطيل الحساب.',
    );
  }

  /// Runs a single-row action and swaps the row it returns into the list.
  ///
  /// The server answers with the row as it now stands, so there is nothing to refetch
  /// and no window where the screen shows a value the database disagrees with.
  Future<void> _replaceRow(
    String rowId,
    Future<AppUser> Function() action,
    String successMessage,
  ) async {
    final users = _users;
    if (users.isEmpty) return;
    try {
      final updated = await action();
      final next = users.map((u) => u.id == rowId ? updated : u).toList();
      emit(UsersActionSuccess(successMessage, next));
      emit(UsersLoaded(next));
    } catch (e) {
      emit(UsersActionFailure(_message(e), users));
    }
  }

  /// Dismisses the credential reveal and returns to the directory.
  void acknowledgeCredentials() {
    if (state is! UsersCredentialsIssued) return;
    emit(UsersLoaded(_users));
  }

  /// Refetches, falling back to the list we already hold.
  ///
  /// Used on the success path only: the account was created, and a refresh that failed
  /// afterwards must not be reported as a failure to create it — that would send the
  /// owner back to a form to redo work the server has already done.
  Future<List<AppUser>> _safeUsers(List<AppUser> fallback) async {
    try {
      return await _getUsers();
    } catch (_) {
      return fallback;
    }
  }

  /// Datasources throw `Exception('<arabic>')`; `toString()` prefixes that with
  /// "Exception: ", which has no business on screen.
  ///
  /// [LicensingFailure] is matched first because it carries its own Arabic text and no
  /// `toString` — falling through would print "Instance of 'LicensingFailure'" at the
  /// exact moment an office hits its operator limit, which is the one refusal that must
  /// read clearly.
  String _message(Object error) => switch (error) {
    LicensingFailure(:final message) => message,
    _ => error.toString().replaceAll('Exception: ', ''),
  };
}
