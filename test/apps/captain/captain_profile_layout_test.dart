import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme_cubit.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme_repository.dart';
import 'package:bmt_app/apps/captain/features/profile/domain/entities/driver_profile.dart';
import 'package:bmt_app/apps/captain/features/profile/presentation/cubit/driver_profile_cubit.dart';
import 'package:bmt_app/apps/captain/features/profile/presentation/cubit/driver_profile_state.dart';
import 'package:bmt_app/apps/captain/features/profile/presentation/pages/driver_profile_page.dart';
import 'package:bmt_app/apps/captain/features/splash/presentation/screens/captain_splash_screen.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// The profile header packs an avatar, name, rating pill and a stats row into a
/// fixed-height sliver, and the identity block is the first thing the captain
/// sees on both the splash and the profile. Both are pure layout, so a pump at
/// a few real screen sizes is what actually proves they fit — the analyzer
/// can't see a RenderFlex overflow.
///
/// Note these assertions are deliberately conservative: `flutter_test` swaps in
/// a test font whose glyphs are far wider than Cairo's, so Arabic strings
/// measure much longer here than on a device. Passing therefore proves the
/// layout holds with room to spare, but a failure is not automatically a
/// user-visible bug — check the real font before contorting a layout to satisfy
/// this file.
class _StubThemeRepository implements CaptainThemeRepository {
  @override
  Future<ThemeMode> loadThemeMode() async => ThemeMode.light;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {}
}

class _StubProfileCubit extends Cubit<DriverProfileState>
    implements DriverProfileCubit {
  _StubProfileCubit(super.initialState);

  @override
  Future<void> load() async {}

  @override
  Future<void> refresh() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DriverProfile _profile({
  String name = 'محمود عبد الرحمن السيد',
  double rating = 4.8,
}) {
  return DriverProfile(
    id: 'd1',
    name: name,
    phone: '01001234567',
    licenseNumber: 'LIC-99120',
    averageRating: rating,
    totalTrips: 1284,
    totalPassengers: 24310,
    vehicleCode: 'BUS-104',
    plateNumber: 'ط ن ج 4821',
    vehicleModel: 'Mercedes Sprinter',
    vehicleCapacity: 24,
    employeeCode: 'EMP-2201',
    licenseExpiryDate: DateTime.now().add(const Duration(days: 400)),
    hireDate: DateTime(2021, 3, 1),
  );
}

Widget _host(Widget child) {
  return BlocProvider<CaptainThemeCubit>(
    create: (_) => CaptainThemeCubit(_StubThemeRepository()),
    child: MaterialApp(
      // Mirrors CaptainApp: the delegates are what load the app's `ar` date
      // symbols, which VerificationCard's DateFormat depends on.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      theme: CaptainTheme.light(),
      home: child,
    ),
  );
}

// iPhone SE, a common mid-size phone, and a tall device.
const _sizes = <String, Size>{
  'small': Size(320, 568),
  'medium': Size(390, 844),
  'large': Size(430, 932),
};

void main() {
  for (final entry in _sizes.entries) {
    testWidgets('profile renders without overflow on ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          BlocProvider<DriverProfileCubit>(
            create: (_) => _StubProfileCubit(DriverProfileLoaded(_profile())),
            child: const DriverProfilePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ملفي'), findsOneWidget);
      expect(find.textContaining('ممتاز'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('profile skeleton renders without overflow on ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          BlocProvider<DriverProfileCubit>(
            create: (_) => _StubProfileCubit(const DriverProfileLoading()),
            child: const DriverProfilePage(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets('splash renders without overflow on ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const CaptainSplashScreen()));
      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.text('كابتن'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('profile header survives a long name and no rating', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        BlocProvider<DriverProfileCubit>(
          create: (_) => _StubProfileCubit(
            DriverProfileLoaded(
              _profile(
                name: 'عبد الرحمن محمد عبد العزيز المستشار الكبير',
                rating: 0,
              ),
            ),
          ),
          child: const DriverProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No rating means no pill — the header must simply close up, not gap.
    expect(find.textContaining('ممتاز'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
