import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/core/theme/client_theme.dart';
import 'package:bmt_app/apps/client/features/auth/domain/entities/remembered_credentials.dart';
import 'package:bmt_app/apps/client/features/auth/domain/repositories/client_auth_repository.dart';
import 'package:bmt_app/apps/client/features/auth/domain/repositories/remember_me_repository.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/clear_remembered_credentials_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/get_remembered_credentials_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/save_remembered_credentials_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/remember_me_coordinator.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Layout guards for the two screens a rider meets before they have an account.
/// Both are Arabic RTL forms that must survive a small screen, a system font
/// two steps up, and dark mode — the states the old bespoke auth chrome was
/// never checked against.
class _FakeAuthRepository implements ClientAuthRepository {
  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUpWithEmail({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}
}

class _EmptyRememberMeRepository implements RememberMeRepository {
  @override
  Future<void> save({required String email, required String password}) async {}

  @override
  Future<RememberedCredentials?> read() async => null;

  @override
  Future<void> clear() async {}
}

ClientAuthCubit _authCubit() {
  final authRepo = _FakeAuthRepository();
  final rememberMeRepo = _EmptyRememberMeRepository();
  return ClientAuthCubit(
    signInWithEmail: SignInWithEmailUseCase(authRepo),
    signUpWithEmail: SignUpWithEmailUseCase(authRepo),
    signOut: SignOutUseCase(authRepo),
    rememberMe: RememberMeCoordinator(
      save: SaveRememberedCredentialsUseCase(rememberMeRepo),
      get: GetRememberedCredentialsUseCase(rememberMeRepo),
      clear: ClearRememberedCredentialsUseCase(rememberMeRepo),
    ),
  );
}

Widget _host(Widget screen, {double scale = 1.0, bool dark = false}) {
  return MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: dark ? ClientTheme.dark() : ClientTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: BlocProvider<ClientAuthCubit>(
      create: (_) => _authCubit(),
      child: screen,
    ),
  );
}

const _sizes = <String, Size>{
  'small': Size(320, 568),
  'medium': Size(390, 844),
};

void main() {
  for (final entry in _sizes.entries) {
    testWidgets('sign-in renders without overflow on ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const SignInScreen()));
      await tester.pumpAndSettle();

      // Hero greeting, both credential fields and the primary action.
      expect(find.text('مرحباً بعودتك'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('تسجيل الدخول'), findsWidgets);
      expect(find.text('تذكرني'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sign-up renders without overflow on ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const SignUpScreen()));
      await tester.pumpAndSettle();

      // Four required inputs plus the optional referral code.
      expect(find.byType(TextFormField), findsNWidgets(5));
      expect(find.text('إنشاء حساب'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.3, 1.6]) {
    testWidgets('sign-in holds at small @ textScale $scale', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const SignInScreen(), scale: scale));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('sign-up holds at small @ textScale $scale', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const SignUpScreen(), scale: scale));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('both screens render in dark mode', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(const SignInScreen(), dark: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_host(const SignUpScreen(), dark: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
