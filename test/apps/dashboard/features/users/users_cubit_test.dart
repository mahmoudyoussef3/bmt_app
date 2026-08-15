import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/features/users/domain/entities/app_user.dart';
import 'package:bmt_app/apps/dashboard/features/users/domain/entities/staff_account.dart';
import 'package:bmt_app/apps/dashboard/features/users/domain/repositories/users_repository.dart';
import 'package:bmt_app/apps/dashboard/features/users/domain/usecases/create_dashboard_user_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/users/domain/usecases/get_users_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/users/domain/usecases/reset_dashboard_user_password_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/users/domain/usecases/set_dashboard_user_status_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/users/domain/usecases/update_user_role_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/users/presentation/cubit/users_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/users/presentation/cubit/users_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeRepo repo;
  late UsersCubit cubit;

  AppUser user({
    String id = 'staff-1',
    String username = 'ops.sara',
    DashboardRole role = DashboardRole.supportAgent,
    String status = 'active',
  }) => AppUser(
    id: id,
    userId: 'auth-$id',
    username: username,
    fullName: 'سارة محمد',
    status: status,
    role: role,
    createdAt: DateTime(2026, 8, 1),
  );

  setUp(() {
    repo = _FakeRepo()..users = [user()];
    cubit = UsersCubit(
      getUsers: GetUsersUseCase(repo),
      updateRole: UpdateUserRoleUseCase(repo),
      createUser: CreateDashboardUserUseCase(repo),
      resetPassword: ResetDashboardUserPasswordUseCase(repo),
      setStatus: SetDashboardUserStatusUseCase(repo),
    );
  });

  tearDown(() => cubit.close());

  group('load', () {
    test('exposes the office staff directory', () async {
      await cubit.load();

      expect(cubit.state, isA<UsersLoaded>());
      expect((cubit.state as UsersLoaded).users.single.username, 'ops.sara');
    });

    test('a failed load is a screen-level error', () async {
      repo.failWith = Exception('تعذر تحميل البيانات.');

      await cubit.load();

      expect(cubit.state, isA<UsersError>());
      expect((cubit.state as UsersError).message, 'تعذر تحميل البيانات.');
    });
  });

  group('createUser', () {
    const request = StaffAccountRequest(username: 'ops.omar');

    test('reveals the credentials once and refreshes the list', () async {
      await cubit.load();
      repo.credentials = const StaffCredentials(
        username: 'ops.omar',
        temporaryPassword: 'Str0ng!Passw0rd',
      );
      repo.users = [user(), user(id: 'staff-2', username: 'ops.omar')];

      await cubit.createUser(request);

      final state = cubit.state as UsersCredentialsIssued;
      expect(state.credentials.temporaryPassword, 'Str0ng!Passw0rd');
      expect(state.credentials.isReset, isFalse);
      expect(state.users, hasLength(2));
    });

    test('rejects an invalid username without calling the server', () async {
      await cubit.load();

      await cubit.createUser(const StaffAccountRequest(username: 'A B'));

      final state = cubit.state as UsersActionFailure;
      expect(state.fieldErrors, contains('username'));
      expect(state.users, hasLength(1), reason: 'the directory survives');
      expect(repo.createCalls, isEmpty);
    });

    test('a refused creation keeps the directory on screen', () async {
      await cubit.load();
      repo.failWith = Exception('اسم الدخول مستخدم بالفعل. اختر اسماً آخر.');

      await cubit.createUser(request);

      final state = cubit.state as UsersActionFailure;
      expect(state.message, 'اسم الدخول مستخدم بالفعل. اختر اسماً آخر.');
      expect(state.users, hasLength(1));
    });

    test('a failed refresh does not undo a successful creation', () async {
      await cubit.load();
      repo.credentials = const StaffCredentials(
        username: 'ops.omar',
        temporaryPassword: 'Str0ng!Passw0rd',
      );
      repo.failListAfterCreate = true;

      await cubit.createUser(request);

      expect(cubit.state, isA<UsersCredentialsIssued>());
      expect((cubit.state as UsersCredentialsIssued).users, hasLength(1));
    });

    test('acknowledging the reveal returns to the directory', () async {
      await cubit.load();
      repo.credentials = const StaffCredentials(username: 'ops.omar');
      await cubit.createUser(request);

      cubit.acknowledgeCredentials();

      expect(cubit.state, isA<UsersLoaded>());
    });
  });

  group('resetPassword', () {
    test('reveals the new password and marks it as a reset', () async {
      await cubit.load();
      repo.credentials = const StaffCredentials(
        username: 'ops.sara',
        temporaryPassword: 'N3w!Passw0rd',
        isReset: true,
      );

      await cubit.resetPassword(user());

      final state = cubit.state as UsersCredentialsIssued;
      expect(state.credentials.isReset, isTrue);
      expect(state.credentials.temporaryPassword, 'N3w!Passw0rd');
    });

    test('refuses a chosen password under ten characters locally', () async {
      await cubit.load();

      await cubit.resetPassword(user(), password: 'short');

      expect(cubit.state, isA<UsersActionFailure>());
      expect(repo.resetCalls, isEmpty);
    });
  });

  group('changeRole', () {
    test('swaps in the row the server returned', () async {
      await cubit.load();
      repo.updated = user(role: DashboardRole.admin);

      await cubit.changeRole('staff-1', DashboardRole.admin);

      expect(cubit.state, isA<UsersLoaded>());
      final users = (cubit.state as UsersLoaded).users;
      expect(users.single.role, DashboardRole.admin);
    });

    test('a refusal keeps the previous role visible', () async {
      await cubit.load();
      repo.failWith = Exception(
        'لا يمكن ترك المكتب بلا مالك نشط. عيّن مالكاً آخر أولاً.',
      );

      await cubit.changeRole('staff-1', DashboardRole.supportAgent);

      final state = cubit.state as UsersActionFailure;
      expect(
        state.message,
        'لا يمكن ترك المكتب بلا مالك نشط. عيّن مالكاً آخر أولاً.',
      );
      expect(state.users.single.role, DashboardRole.supportAgent);
    });
  });

  group('setActive', () {
    test('disabling swaps in the disabled row', () async {
      await cubit.load();
      repo.updated = user(status: 'disabled');

      await cubit.setActive(user(), active: false);

      final users = (cubit.state as UsersLoaded).users;
      expect(users.single.isActive, isFalse);
      expect(repo.statusCalls.single, ('staff-1', false));
    });

    test('re-enabling asks the server for the active state', () async {
      await cubit.load();
      repo.users = [user(status: 'disabled')];
      await cubit.load();
      repo.updated = user();

      await cubit.setActive(user(status: 'disabled'), active: true);

      expect((cubit.state as UsersLoaded).users.single.isActive, isTrue);
      expect(repo.statusCalls.single, ('staff-1', true));
    });
  });
}

class _FakeRepo implements UsersRepository {
  List<AppUser> users = const [];
  StaffCredentials credentials = const StaffCredentials(username: 'ops.omar');
  AppUser? updated;
  Object? failWith;

  /// Makes only the post-creation refresh fail, so the cubit's "the account exists
  /// even if the list did not reload" path can be exercised.
  bool failListAfterCreate = false;
  bool _created = false;

  final List<StaffAccountRequest> createCalls = [];
  final List<String> resetCalls = [];
  final List<(String, bool)> statusCalls = [];

  @override
  Future<List<AppUser>> getUsers() async {
    if (failWith != null) throw failWith!;
    if (failListAfterCreate && _created) throw Exception('تعذر تحديث القائمة.');
    return users;
  }

  @override
  Future<StaffCredentials> createUser(StaffAccountRequest request) async {
    if (failWith != null) throw failWith!;
    createCalls.add(request);
    _created = true;
    return credentials;
  }

  @override
  Future<StaffCredentials> resetPassword({
    required String officeUserId,
    String password = '',
  }) async {
    if (failWith != null) throw failWith!;
    resetCalls.add(officeUserId);
    return credentials;
  }

  @override
  Future<AppUser> updateUserRole(String userRoleId, DashboardRole role) async {
    if (failWith != null) throw failWith!;
    return updated!;
  }

  @override
  Future<AppUser> setUserStatus(
    String userRoleId, {
    required bool active,
  }) async {
    if (failWith != null) throw failWith!;
    statusCalls.add((userRoleId, active));
    return updated!;
  }

  @override
  Future<DashboardRole?> getCurrentUserRole() async => DashboardRole.admin;
}
