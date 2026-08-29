/// Visual QA harness for the office-registration screen — the EWT brand sweep
/// beside the form, the two field groups, the publish notice, the folded band
/// below [DashboardAuthLayout.splitBreakpoint], and the inline failure banner.
/// None of that can be judged from code.
///
/// Not a test of behaviour and deliberately not part of the suite's assertions:
/// run it with `--update-goldens` and look at the PNGs it writes to
/// `_captures/`.
///
///     flutter test test/apps/dashboard/features/auth/dashboard_sign_up_visual_capture.dart --update-goldens
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/auth/presentation/cubit/dashboard_auth_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/auth/presentation/screens/dashboard_sign_up_screen.dart';

import 'auth_capture_theme.dart';

void main() {
  setUpAll(loadCaptureFont);

  testWidgets('split layout, light', (tester) async {
    await _capture(
      tester,
      'signup_1_split_light',
      dark: false,
      width: 1440,
      height: 1080,
    );
  });

  testWidgets('split layout, dark', (tester) async {
    await _capture(
      tester,
      'signup_2_split_dark',
      dark: true,
      width: 1440,
      height: 1080,
    );
  });

  testWidgets('narrow — the brand panel folds into a band', (tester) async {
    await _capture(
      tester,
      'signup_3_narrow_light',
      dark: false,
      width: 420,
      height: 1180,
    );
  });

  testWidgets('a rejected registration states itself above the fields', (
    tester,
  ) async {
    await _capture(
      tester,
      'signup_4_error_dark',
      dark: true,
      width: 1440,
      height: 1080,
      error: 'هذا البريد الإلكتروني مسجل بالفعل.',
    );
  });

  testWidgets('mismatched passwords — both rules stated under their fields', (
    tester,
  ) async {
    await _capture(
      tester,
      'signup_5_validation_light',
      dark: false,
      width: 1440,
      height: 1080,
      invalid: true,
    );
  });

  testWidgets('creating the office — the form locks and the button spins', (
    tester,
  ) async {
    await _capture(
      tester,
      'signup_6_loading_light',
      dark: false,
      width: 1440,
      height: 1080,
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
  bool invalid = false,
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
          child: DashboardSignUpScreen(onBackToLogin: () {}),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }

  if (invalid) {
    // Drive the field errors through the real path — a short password and a
    // confirmation that does not match it, then the button the operator would
    // actually press.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'مثال: مكتب النيل للنقل'),
      'مكتب النيل',
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(2), 'short');
    await tester.enterText(fields.at(3), 'shorter');
    await tester.tap(find.widgetWithText(FilledButton, 'إنشاء المكتب'));
    await tester.pumpAndSettle();
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
