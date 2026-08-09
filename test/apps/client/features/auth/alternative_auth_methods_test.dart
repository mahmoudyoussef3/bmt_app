import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/core/theme/client_theme.dart';
import 'package:bmt_app/apps/client/features/auth/domain/entities/auth_method.dart';
import 'package:bmt_app/apps/client/features/auth/domain/entities/auth_method_failure.dart';
import 'package:bmt_app/apps/client/features/auth/domain/entities/otp_challenge.dart';
import 'package:bmt_app/apps/client/features/auth/domain/entities/social_auth_result.dart';
import 'package:bmt_app/apps/client/features/auth/domain/repositories/phone_auth_repository.dart';
import 'package:bmt_app/apps/client/features/auth/domain/repositories/social_auth_repository.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/sign_in_with_apple_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/social_auth_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/social_auth_state.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/routes/otp_verification_arguments.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/welcome_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/alternative_methods/auth_alternative_methods.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/alternative_methods/coming_soon_badge.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/alternative_methods/social_auth_button.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Guards for the sign-in methods that ship as UI before their providers do.
///
/// The whole point of this phase is that Google, Apple and phone/OTP are
/// *visible and inert*. Two things must therefore stay true, and neither is
/// obvious from reading a widget: nothing a rider can touch reaches a provider,
/// and the screens behind those buttons still survive Arabic RTL on a small
/// phone at a large system font.

/// Records every call so a test can assert that none happened.
class _RecordingSocialAuthRepository implements SocialAuthRepository {
  final calls = <String>[];

  @override
  Future<SocialAuthResult> signInWithGoogle() async {
    calls.add('google');
    return const SocialAuthResult(
      method: AuthMethod.google,
      userId: 'u',
      isNewAccount: false,
    );
  }

  @override
  Future<SocialAuthResult> signInWithApple() async {
    calls.add('apple');
    return const SocialAuthResult(
      method: AuthMethod.apple,
      userId: 'u',
      isNewAccount: false,
    );
  }
}

class _RecordingPhoneAuthRepository implements PhoneAuthRepository {
  final calls = <String>[];

  @override
  Future<OtpChallenge> sendOtp(String phone) async {
    calls.add('send:$phone');
    return OtpChallenge(
      phone: phone,
      expiresAt: DateTime(2030),
      resendAvailableAt: DateTime(2030),
    );
  }

  @override
  Future<SocialAuthResult> verifyOtp({
    required String phone,
    required String code,
  }) async {
    calls.add('verify:$phone:$code');
    return const SocialAuthResult(
      method: AuthMethod.phoneOtp,
      userId: 'u',
      isNewAccount: false,
    );
  }
}

({SocialAuthCubit cubit, List<String> social, List<String> phone}) _cubit() {
  final social = _RecordingSocialAuthRepository();
  final phone = _RecordingPhoneAuthRepository();
  return (
    cubit: SocialAuthCubit(
      signInWithGoogle: SignInWithGoogleUseCase(social),
      signInWithApple: SignInWithAppleUseCase(social),
      sendPhoneOtp: SendPhoneOtpUseCase(phone),
      verifyPhoneOtp: VerifyPhoneOtpUseCase(phone),
    ),
    social: social.calls,
    phone: phone.calls,
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
    home: BlocProvider<SocialAuthCubit>(
      create: (_) => _cubit().cubit,
      child: screen,
    ),
  );
}

const _sizes = <String, Size>{
  'small': Size(320, 568),
  'medium': Size(390, 844),
};

void main() {
  group('the pending methods are inert', () {
    test('every alternative method is switched off in this build', () {
      // The one switch the whole feature hangs on. If this ever flips without
      // a provider behind it, the buttons below become live and the cubit
      // starts calling a datasource that throws.
      for (final method in AuthMethod.values) {
        expect(
          method.isAvailable,
          isFalse,
          reason: '${method.name} must stay off until its provider is wired',
        );
      }
    });

    test('the cubit refuses each method without touching a use case', () async {
      final harness = _cubit();

      await harness.cubit.signInWithGoogle();
      await harness.cubit.signInWithApple();
      await harness.cubit.sendOtp('+201012345678');

      expect(harness.social, isEmpty);
      expect(harness.phone, isEmpty);
      expect(harness.cubit.state.status, SocialAuthStatus.failed);
      expect(harness.cubit.state.failure, AuthMethodFailure.unavailable);
    });

    test('verifying is impossible before a code was ever sent', () async {
      final harness = _cubit();

      await harness.cubit.verifyOtp('123456');

      expect(harness.phone, isEmpty);
      // Not even a failure: there is nothing to verify against, so the cubit
      // has nothing to report.
      expect(harness.cubit.state.status, SocialAuthStatus.initial);
    });

    testWidgets('tapping a provider button does nothing at all', (
      tester,
    ) async {
      final harness = _cubit();
      var pushed = 0;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ClientTheme.light(),
          onGenerateRoute: (settings) {
            pushed++;
            return MaterialPageRoute(builder: (_) => const SizedBox.shrink());
          },
          home: BlocProvider<SocialAuthCubit>.value(
            value: harness.cubit,
            child: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AuthAlternativeMethods(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      pushed = 0; // ignore the initial route

      final buttons = find.byType(SocialAuthButton);
      expect(buttons, findsNWidgets(3));
      for (var index = 0; index < 3; index++) {
        await tester.tap(buttons.at(index), warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      expect(pushed, 0, reason: 'no provider button may navigate');
      expect(harness.social, isEmpty);
      expect(harness.phone, isEmpty);
      expect(harness.cubit.state.status, SocialAuthStatus.initial);
    });

    testWidgets('each pending method says so', (tester) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: AuthAlternativeMethods(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ComingSoonBadge), findsWidgets);
      expect(find.text('قريباً'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('phone and OTP screens hold their layout', () {
    for (final entry in _sizes.entries) {
      testWidgets('phone login renders on ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_host(const PhoneLoginScreen()));
        await tester.pumpAndSettle();

        expect(find.text('+20'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.text('إرسال رمز التحقق'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('otp verification renders on ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _host(
            const OtpVerificationScreen(
              args: OtpVerificationArguments(phone: '+201012345678'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The number is shown grouped and left-to-right, never re-ordered into
        // something the rider would not recognise.
        expect(find.text('+20 101 2345 678'), findsOneWidget);
        expect(find.text('تغيير رقم الهاتف'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in [1.3, 1.6]) {
      testWidgets('phone login holds at small @ textScale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_host(const PhoneLoginScreen(), scale: scale));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('otp holds at small @ textScale $scale', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _host(
            const OtpVerificationScreen(
              args: OtpVerificationArguments(phone: '+201012345678'),
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('both render in dark mode', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const PhoneLoginScreen(), dark: true));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _host(
          const OtpVerificationScreen(
            args: OtpVerificationArguments(phone: '+201012345678'),
          ),
          dark: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the code field accepts six digits and reports them', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          const OtpVerificationScreen(
            args: OtpVerificationArguments(phone: '+201012345678'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Typing must work even with no provider: a code field that will not take
      // digits is not a preview of anything.
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();

      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        expect(find.text(digit), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('the welcome screen still fits', () {
    // The screen that gained the most: a divider and three tiles between the
    // create-account button and the guest link, on the one screen in the app
    // that has no scroll room to spare.
    Widget welcome({double scale = 1.0, bool dark = false}) => MaterialApp(
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
      home: BlocProvider<LocaleCubit>(
        create: (_) => LocaleCubit(),
        child: const WelcomeScreen(),
      ),
    );

    for (final entry in _sizes.entries) {
      testWidgets('renders on ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(welcome());
        await tester.pumpAndSettle();

        // The working method keeps the primary button; the pending ones sit
        // under the divider as tiles.
        expect(find.text('المتابعة بالبريد الإلكتروني'), findsOneWidget);
        expect(find.byType(SocialAuthButton), findsNWidgets(3));
        expect(find.text('Google'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in [1.3, 1.6]) {
      testWidgets('holds at small @ textScale $scale', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(welcome(scale: scale));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('renders in dark mode', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(welcome(dark: true));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('OtpVerificationArguments', () {
    test('survives a round trip through route arguments', () {
      const original = OtpVerificationArguments(
        phone: '+201012345678',
        codeLength: 4,
        expiresInSeconds: 120,
        resendAfterSeconds: 45,
      );

      final restored = OtpVerificationArguments.fromArguments(
        original.toArguments(),
      );

      expect(restored.phone, original.phone);
      expect(restored.codeLength, original.codeLength);
      expect(restored.expiresInSeconds, original.expiresInSeconds);
      expect(restored.resendAfterSeconds, original.resendAfterSeconds);
    });

    test('a stale or empty push is rejected rather than half-rendered', () {
      expect(OtpVerificationArguments.fromArguments(null).isValid, isFalse);
      expect(OtpVerificationArguments.fromArguments({}).isValid, isFalse);
      expect(
        OtpVerificationArguments.fromArguments({
          'phone': '+201012345678',
        }).isValid,
        isTrue,
      );
    });

    test('a number it cannot group is shown as-is, never mangled', () {
      const args = OtpVerificationArguments(phone: '+449876543');
      expect(args.displayPhone, '+449876543');
    });
  });
}
