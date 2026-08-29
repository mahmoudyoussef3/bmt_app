/// Visual QA harness for the dashboard sign-in screen — the EWT brand sweep
/// beside the form, the folded band below [DashboardAuthLayout.splitBreakpoint],
/// and the inline failure banner. None of that can be judged from code.
///
/// Not a test of behaviour and deliberately not part of the suite's assertions:
/// run it with `--update-goldens` and look at the PNGs it writes to
/// `_captures/`.
///
///     flutter test test/apps/dashboard/features/auth/dashboard_login_visual_capture.dart --update-goldens
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/auth/presentation/cubit/dashboard_auth_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/auth/presentation/screens/dashboard_login_screen.dart';

import 'auth_capture_theme.dart';

void main() {
  setUpAll(loadCaptureFont);

  testWidgets('split layout, light', (tester) async {
    await _capture(
      tester,
      'login_1_split_light',
      dark: false,
      width: 1440,
      height: 900,
    );
  });

  testWidgets('split layout, dark', (tester) async {
    await _capture(
      tester,
      'login_2_split_dark',
      dark: true,
      width: 1440,
      height: 900,
    );
  });

  testWidgets('narrow — the brand panel folds into a band', (tester) async {
    await _capture(
      tester,
      'login_3_narrow_light',
      dark: false,
      width: 420,
      height: 900,
    );
  });

  testWidgets('a rejected sign-in states itself above the fields', (
    tester,
  ) async {
    await _capture(
      tester,
      'login_4_error_light',
      dark: false,
      width: 1440,
      height: 900,
      error: 'اسم المستخدم أو كلمة المرور غير صحيحة.',
    );
  });

  testWidgets('signing in — the form locks and the button spins', (
    tester,
  ) async {
    await _capture(
      tester,
      'login_5_loading_dark',
      dark: true,
      width: 1440,
      height: 900,
      loading: true,
      settle: false,
    );
  });
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required bool dark,
  required double width,
  required double height,
  String? error,
  bool loading = false,
  bool settle = true,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final cubit = _StaticAuthCubit(
    loading ? const DashboardAuthLoading() : const DashboardAuthSignedOut(),
  );
  addTearDown(cubit.close);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeWithHostFont(dark: dark),
      home: RepaintBoundary(
        key: key,
        child: BlocProvider<DashboardAuthCubit>.value(
          value: cubit,
          child: DashboardLoginScreen(onCreateOffice: () {}),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }

  if (error != null) {
    // Drive the banner through the real path — the screen takes the message
    // off a DashboardAuthError emission, then resets the cubit.
    cubit.fail(error);
    await tester.pumpAndSettle();
  }

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

class _StaticAuthCubit extends Cubit<DashboardAuthState>
    implements DashboardAuthCubit {
  _StaticAuthCubit(super.initialState);

  void fail(String message) => emit(DashboardAuthError(message));

  @override
  void resetError() {
    if (state is DashboardAuthError) emit(const DashboardAuthSignedOut());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
