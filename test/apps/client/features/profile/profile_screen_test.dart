import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

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
import 'package:bmt_app/apps/client/features/auth/presentation/routes/auth_routes.dart';
import 'package:bmt_app/apps/client/features/profile/domain/entities/client_profile.dart';
import 'package:bmt_app/apps/client/features/profile/domain/repositories/profile_repository.dart';
import 'package:bmt_app/apps/client/features/profile/domain/usecases/get_profile_data_usecase.dart';
import 'package:bmt_app/apps/client/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/screens/profile_screen.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';
import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/remember_me_coordinator.dart';

class _StubProfileRepository implements ProfileRepository {
  _StubProfileRepository(this.profile);

  final ClientProfile profile;

  @override
  Future<ClientProfile> getProfile() async => profile;

  @override
  Future<ClientProfile> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async => profile;
}

class _StubAuthRepository implements ClientAuthRepository {
  int signOutCalls = 0;

  @override
  Future<void> signOut() async => signOutCalls++;

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
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}
}

class _StubRememberMeRepository implements RememberMeRepository {
  @override
  Future<void> save({required String email, required String password}) async {}

  @override
  Future<RememberedCredentials?> read() async => null;

  @override
  Future<void> clear() async {}
}

const _profile = ClientProfile(
  id: 'c1',
  name: 'Mahmoud Youssef',
  email: 'mahmoud@example.com',
  phone: '+201012345678',
  completedTrips: 12,
  upcomingTrips: 2,
);

Widget _app({
  ClientProfile profile = _profile,
  _StubAuthRepository? auth,
  Locale locale = const Locale('en'),
}) {
  final authRepository = auth ?? _StubAuthRepository();
  final profileRepository = _StubProfileRepository(profile);

  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => LocaleCubit()),
      BlocProvider(
        create: (_) => ProfileCubit(
          GetProfileDataUseCase(profileRepository),
          UpdateProfileUseCase(profileRepository),
        ),
      ),
      BlocProvider(
        create: (_) {
          final rememberMeRepository = _StubRememberMeRepository();
          return ClientAuthCubit(
            signInWithEmail: SignInWithEmailUseCase(authRepository),
            signUpWithEmail: SignUpWithEmailUseCase(authRepository),
            signOut: SignOutUseCase(authRepository),
            rememberMe: RememberMeCoordinator(
              save: SaveRememberedCredentialsUseCase(rememberMeRepository),
              get: GetRememberedCredentialsUseCase(rememberMeRepository),
              clear: ClearRememberedCredentialsUseCase(rememberMeRepository),
            ),
          );
        },
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProfileScreen(onOpenRoute: (_, [_]) {}),
      routes: {
        AuthRoutes.welcome: (_) => const Scaffold(body: Text('welcome screen')),
      },
    ),
  );
}

/// The hub is a lazy list, so rows below the fold are never built. A tall
/// viewport puts the whole hub on screen, which is what these tests are about.
Future<void> _pumpHub(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the hub renders the rider and their real numbers', (
    tester,
  ) async {
    await _pumpHub(tester, _app());

    expect(find.text('Mahmoud Youssef'), findsOneWidget);
    expect(find.text('+201012345678'), findsOneWidget);
    // Trips taken / upcoming, straight from their bookings.
    expect(find.text('12'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('settings live on the hub, and show their current value', (
    tester,
  ) async {
    await _pumpHub(tester, _app());

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Personal details'), findsOneWidget);
    expect(find.text('Terms & conditions'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    // The active language is readable without opening anything.
    expect(find.text('English'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
  });

  testWidgets('rewards, loyalty and messages are not offered', (tester) async {
    await _pumpHub(tester, _app());

    expect(find.textContaining('Rewards'), findsNothing);
    expect(find.textContaining('Loyalty'), findsNothing);
    expect(find.textContaining('Messages'), findsNothing);
  });

  testWidgets('an incomplete profile is prompted to complete itself', (
    tester,
  ) async {
    await _pumpHub(
      tester,
      _app(
        profile: const ClientProfile(
          id: 'c1',
          name: 'Mahmoud',
          email: '',
          phone: '',
        ),
      ),
    );

    expect(find.text('Finish setting up your account'), findsOneWidget);
  });

  testWidgets('logging out asks first, and does nothing if declined', (
    tester,
  ) async {
    final auth = _StubAuthRepository();
    await _pumpHub(tester, _app(auth: auth));

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(auth.signOutCalls, 0);
  });

  testWidgets('confirming the dialog actually ends the session', (
    tester,
  ) async {
    final auth = _StubAuthRepository();
    await _pumpHub(tester, _app(auth: auth));

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    // The dialog's confirm button, not the screen's button behind it.
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(auth.signOutCalls, 1);
    // The regression this screen exists to fix: clearing the session is not
    // enough — sign-in makes the shell the root of the stack, so logging out
    // must also reset the stack or the rider stays on a signed-out profile.
    expect(find.text('welcome screen'), findsOneWidget);
    expect(find.text('Mahmoud Youssef'), findsNothing);
  });

  testWidgets('the hub is translated and laid out right-to-left in Arabic', (
    tester,
  ) async {
    await _pumpHub(tester, _app(locale: const Locale('ar')));

    expect(find.text('اللغة'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('اللغة'))),
      TextDirection.rtl,
    );
  });
}
