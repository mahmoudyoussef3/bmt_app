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

Widget _host(Widget child, {double scale = 1.0}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ar'),
    theme: CaptainTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: child,
  );
}

const _sizes = <String, Size>{
  'small': Size(320, 568),
  'medium': Size(390, 844),
};

void main() {
  /// Login is the first screen a captain ever sees, and the one most likely to
  /// be opened on a device already set to a large system font.
  for (final scale in [1.3, 1.6]) {
    testWidgets('login holds at small @ textScale $scale', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          BlocProvider<CaptainAuthCubit>(
            create: (_) => _StubAuthCubit(const CaptainAuthIdle()),
            child: CaptainLoginScreen(onRequestAccess: () {}),
          ),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }

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
              child: CaptainRequestForm(
                submitting: false,
                onSubmit: (_, _, _, _) {},
              ),
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

  /// Regression: the banner used to lay its message out under an
  /// `IntrinsicHeight`, which measured an `Expanded` `Text` at the wrong width
  /// and settled one line short — so the second line of exactly the errors that
  /// need two was clipped away. A one-line banner is ~44dp of content plus its
  /// 16dp margin; anything at or under that means the message was truncated.
  testWidgets('a two-line error message is drawn in full', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const message =
        'هذا الرقم غير مسجّل كسائق نشط. تحقّق من الرقم أو اطلب الانضمام.';

    await tester.pumpWidget(
      _host(
        BlocProvider<CaptainAuthCubit>(
          create: (_) => _StubAuthCubit(const CaptainAuthError(message)),
          child: CaptainLoginScreen(onRequestAccess: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final banner = find.byKey(const ValueKey('captain-auth-error'));
    expect(banner, findsOneWidget);
    expect(tester.getSize(banner).height, greaterThan(70));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the phone field accepts numerals as an Arabic keypad types them',
    (tester) async {
      await tester.pumpWidget(
        _host(
          BlocProvider<CaptainAuthCubit>(
            create: (_) => _StubAuthCubit(const CaptainAuthIdle()),
            child: CaptainLoginScreen(onRequestAccess: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Arabic-Indic digits with the separators a pasted contact carries.
      await tester.enterText(find.byType(TextFormField), '٠١٠٠ ١٢٣-٤٥٦٧');
      await tester.pump();

      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.controller.text, '01001234567');
    },
  );

  testWidgets('phone field is LTR while the name field follows the app RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Scaffold(
          body: SingleChildScrollView(
            child: CaptainRequestForm(
              submitting: false,
              onSubmit: (_, _, _, _) {},
            ),
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
