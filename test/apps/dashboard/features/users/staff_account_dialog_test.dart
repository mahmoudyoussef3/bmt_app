/// Regression tests for «إضافة مستخدم» — the dialog that reported as doing
/// nothing at all.
///
/// The failure was never in the cubit or the network: it was that the two things
/// the operator needs — the primary action, and the reason a submission was
/// refused — both lived inside the dialog's scrolling body. On any console
/// shorter than ~800px «إنشاء الحساب» sat below the fold with only «إلغاء»
/// visible in the pinned action bar, so an owner filled the form and found
/// nothing to press. These tests pin the geometry at the sizes that broke.
library;

import 'dart:async';

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
import 'package:bmt_app/apps/dashboard/features/users/presentation/widgets/staff_account_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeRepo repo;
  late UsersCubit cubit;

  setUp(() {
    repo = _FakeRepo();
    cubit = UsersCubit(
      getUsers: GetUsersUseCase(repo),
      updateRole: UpdateUserRoleUseCase(repo),
      createUser: CreateDashboardUserUseCase(repo),
      resetPassword: ResetDashboardUserPasswordUseCase(repo),
      setStatus: SetDashboardUserStatusUseCase(repo),
    );
  });

  // Fire-and-forget: an awaited `Bloc.close()` inside a `testWidgets` tear-down
  // never completes in the fake-async zone and hangs the file with no failure.
  tearDown(() {
    cubit.close();
  });

  Finder submitButton() => find.widgetWithText(FilledButton, 'إنشاء الحساب');
  Finder usernameField() => find.widgetWithText(TextFormField, 'اسم الدخول *');

  Future<void> openDialog(
    WidgetTester tester, {
    Size size = const Size(1280, 720),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocProvider.value(
            value: cubit,
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showStaffAccountDialog(context),
                    child: const Text('فتح'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
  }

  /// Whether [finder] is drawn inside the window at all — the check the old
  /// layout failed, and the one no amount of scrolling should be needed to pass.
  bool isOnScreen(WidgetTester tester, Finder finder) {
    final rect = tester.getRect(finder);
    final screen = Offset.zero & tester.view.physicalSize;
    return screen.contains(rect.topLeft) && screen.contains(rect.bottomRight);
  }

  group('the primary action is always reachable', () {
    for (final size in const [
      Size(1280, 720),
      Size(1280, 800),
      Size(1100, 660),
    ]) {
      testWidgets('at $size, with a generated password', (tester) async {
        await openDialog(tester, size: size);
        expect(isOnScreen(tester, submitButton()), isTrue);
      });

      testWidgets('at $size, with an owner-chosen password', (tester) async {
        await openDialog(tester, size: size);
        // The tallest the form ever gets: the password input appears and used to
        // push the old in-body button off screen at every size tested.
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(isOnScreen(tester, submitButton()), isTrue);
      });
    }
  });

  testWidgets(
    'a refusal is shown without scrolling, and the dialog stays open',
    (tester) async {
      repo.failWith = Exception('اسم الدخول مستخدم بالفعل. اختر اسماً آخر.');
      await openDialog(tester);

      await tester.enterText(usernameField(), 'sara.ops');
      await tester.tap(submitButton());
      await tester.pumpAndSettle();

      final banner = find.text('اسم الدخول مستخدم بالفعل. اختر اسماً آخر.');
      expect(banner, findsOneWidget);
      expect(isOnScreen(tester, banner), isTrue);
      expect(find.byType(AlertDialog), findsOneWidget);
    },
  );

  testWidgets('a server-rejected field stops refusing once it is corrected', (
    tester,
  ) async {
    await openDialog(tester);

    // Too short: the cubit refuses locally and answers with a field error.
    await tester.enterText(usernameField(), 'ab');
    await tester.tap(submitButton());
    await tester.pumpAndSettle();
    expect(repo.createCalls, 0);

    // Correcting the field must release the button. Before the fix the stale
    // field error kept failing `validate()`, so no further submission ever left
    // the form and the button was inert for the rest of the dialog's life.
    await tester.enterText(usernameField(), 'sara.ops');
    await tester.tap(submitButton());
    await tester.pumpAndSettle();
    expect(repo.createCalls, 1);
  });

  testWidgets('cancel stays live while a submission is in flight', (
    tester,
  ) async {
    final gate = Completer<StaffCredentials>();
    repo.pending = gate;
    await openDialog(tester);

    await tester.enterText(usernameField(), 'sara.ops');
    await tester.tap(submitButton());
    await tester.pump();

    // The label switches to «جارٍ الإنشاء…» while the call is out, so the button
    // is found by its place in the action bar rather than by its text.
    final action = find.byType(FilledButton);
    expect(tester.widget<FilledButton>(action).onPressed, isNull);
    final cancel = find.widgetWithText(TextButton, 'إلغاء');
    expect(tester.widget<TextButton>(cancel).onPressed, isNotNull);

    // A modal with every control disabled has no exit when a request stalls.
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    gate.complete(const StaffCredentials(username: 'sara.ops'));
    await tester.pumpAndSettle();
  });

  testWidgets('the login name is kept in the shape the server accepts', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.enterText(usernameField(), 'Sara Ops!سارة.2');
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller?.text,
      'saraops.2',
    );
  });

  testWidgets('a created account closes the dialog exactly once', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.enterText(usernameField(), 'sara.ops');
    await tester.tap(submitButton());
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(repo.createCalls, 1);
  });
}

class _FakeRepo implements UsersRepository {
  Object? failWith;
  Completer<StaffCredentials>? pending;
  int createCalls = 0;

  @override
  Future<StaffCredentials> createUser(StaffAccountRequest request) async {
    createCalls++;
    if (failWith != null) throw failWith!;
    final gate = pending;
    if (gate != null) return gate.future;
    return StaffCredentials(
      username: request.username,
      temporaryPassword: 'Aa1!aaaaaaaaaaaa',
    );
  }

  @override
  Future<DashboardRole?> getCurrentUserRole() async => DashboardRole.admin;

  @override
  Future<List<AppUser>> getUsers() async => const [];

  @override
  Future<StaffCredentials> resetPassword({
    required String officeUserId,
    String password = '',
  }) async => const StaffCredentials(username: 'x', isReset: true);

  @override
  Future<AppUser> setUserStatus(String userRoleId, {required bool active}) =>
      throw UnimplementedError();

  @override
  Future<AppUser> updateUserRole(String userRoleId, DashboardRole role) =>
      throw UnimplementedError();
}
