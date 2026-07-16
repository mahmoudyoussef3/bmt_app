import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/features/auth/presentation/cubit/captain_auth_cubit.dart';
import 'package:bmt_app/apps/captain/features/auth/presentation/screens/captain_login_screen.dart';
import 'package:bmt_app/apps/captain/features/onboarding/presentation/widgets/captain_request_form.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Layout guards for the captain's two auth screens. Both are Arabic RTL forms
/// that must survive a keyboard, a small screen and an error banner at once.
///
/// As with the profile suite, `flutter_test`'s stand-in font is much wider than
/// Cairo, so these bounds are conservative rather than pixel-exact.
class _StubAuthCubit extends Cubit<CaptainAuthState>
    implements CaptainAuthCubit {
  _StubAuthCubit(super.initialState);

  @override
  Future<String?> loadRememberedPhone() async => null;

  @override
  void resetError() {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _host(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ar'),
    theme: CaptainTheme.light(),
    home: child,
  );
}

const _sizes = <String, Size>{
  'small': Size(320, 568),
  'medium': Size(390, 844),
};

void main() {
  for (final entry in _sizes.entries) {
    testWidgets('login renders without overflow on ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          BlocProvider<CaptainAuthCubit>(
            create: (_) => _StubAuthCubit(const CaptainAuthIdle()),
            child: CaptainLoginScreen(onRequestAccess: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.text('كابتن جديد؟'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('request form renders without overflow on ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: CaptainRequestForm(submitting: false, onSubmit: (_, _) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إرسال الطلب'), findsOneWidget);
      // The three onboarding stages must all be present.
      expect(find.text('يراجع فريق العمليات طلبك'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('login surfaces the error banner without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        BlocProvider<CaptainAuthCubit>(
          create: (_) =>
              _StubAuthCubit(const CaptainAuthError('رقم الهاتف غير مسجل')),
          child: CaptainLoginScreen(onRequestAccess: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('رقم الهاتف غير مسجل'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone field is LTR while the name field follows the app RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Scaffold(
          body: SingleChildScrollView(
            child: CaptainRequestForm(submitting: false, onSubmit: (_, _) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields, hasLength(2));

    // Name stays with the ambient Arabic direction; only the digits go LTR.
    final name = tester.widget<EditableText>(find.byType(EditableText).first);
    final phone = tester.widget<EditableText>(find.byType(EditableText).last);
    expect(name.textDirection, isNull);
    expect(phone.textDirection, TextDirection.ltr);
  });
}
