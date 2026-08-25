import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme_cubit.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme_repository.dart';
import 'package:bmt_app/apps/captain/features/notifications/presentation/cubit/captain_notification_badge_cubit.dart';
import 'package:bmt_app/apps/captain/features/profile/domain/entities/driver_profile.dart';
import 'package:bmt_app/apps/captain/features/profile/presentation/cubit/driver_profile_cubit.dart';
import 'package:bmt_app/apps/captain/features/profile/presentation/cubit/driver_profile_state.dart';
import 'package:bmt_app/apps/captain/features/profile/presentation/pages/driver_profile_page.dart';
import 'package:bmt_app/apps/captain/features/splash/presentation/screens/captain_splash_screen.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// The profile header packs an avatar, name and rating pill onto a single
/// toolbar row, and the identity block is the first thing the captain sees on
/// both the splash and the profile. Both are pure layout, so a pump at a few
/// real screen sizes is what actually proves they fit — the analyzer can't see
/// a RenderFlex overflow.
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

/// `CaptainRootHeader` carries the notification bell on every root tab now,
/// so any full-page pump needs this in the tree — the shell provides the real
/// one in the app itself.
class _StubNotificationBadgeCubit extends Cubit<int>
    implements CaptainNotificationBadgeCubit {
  _StubNotificationBadgeCubit() : super(0);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DriverProfile _profile({
  String name = 'محمود عبد الرحمن السيد',
  double rating = 4.8,
  String plate = 'ط ن ج 4821',
  String license = 'LIC-99120',
  String model = 'Mercedes Sprinter',
}) {
  return DriverProfile(
    id: 'd1',
    name: name,
    phone: '01001234567',
    licenseNumber: license,
    averageRating: rating,
    totalTrips: 1284,
    totalPassengers: 24310,
    vehicleCode: 'BUS-104',
    plateNumber: plate,
    vehicleModel: model,
    vehicleCapacity: 24,
    employeeCode: 'EMP-2201',
    licenseExpiryDate: DateTime.now().add(const Duration(days: 400)),
    hireDate: DateTime(2021, 3, 1),
  );
}

Widget _host(Widget child, {double scale = 1.0}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<CaptainThemeCubit>(
        create: (_) => CaptainThemeCubit(_StubThemeRepository()),
      ),
      BlocProvider<CaptainNotificationBadgeCubit>(
        create: (_) => _StubNotificationBadgeCubit(),
      ),
    ],
    child: MaterialApp(
      // Mirrors CaptainApp: the delegates are what load the app's `ar` date
      // symbols, which VerificationCard's DateFormat depends on.
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

      // The captain's name is the header's title — there is no separate screen
      // title to assert on.
      expect(find.text('محمود عبد الرحمن السيد'), findsOneWidget);

      // The rating sits with the rest of the account facts, which is below the
      // fold on the smallest phone — and a sliver list does not build what it
      // has not scrolled to. Dragging to the bottom also lays out every row on
      // the page, which is what the overflow assertion below is really for.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
      await tester.pumpAndSettle();

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

  /// The screen runs RTL, but the values it shows are identifiers, not prose.
  /// Inheriting the screen's direction reorders the runs inside them — a latin
  /// plate `ABC 1234` renders as `1234 ABC` — and hardcoding LTR only moves the
  /// bug onto the Egyptian plates this fleet actually runs. Each value has to
  /// resolve its own direction, so both are pinned here.
  testWidgets('identifiers resolve their own direction, not the screen\'s', (
    tester,
  ) async {
    // Tall enough that every card is built and laid out without scrolling —
    // this asserts on direction, not on what fits.
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Future<void> pumpWithPlate(String plate) async {
      await tester.pumpWidget(
        _host(
          BlocProvider<DriverProfileCubit>(
            // Keyed per plate: without it the second pump updates the tree in
            // place, `create` never re-runs, and the first profile stays put.
            key: ValueKey(plate),
            create: (_) =>
                _StubProfileCubit(DriverProfileLoaded(_profile(plate: plate))),
            child: const DriverProfilePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpWithPlate('ABC 1234');
    expect(
      Directionality.of(tester.element(find.text('ABC 1234'))),
      TextDirection.ltr,
    );
    for (final value in ['01001234567', 'EMP-2201', 'LIC-99120']) {
      expect(
        Directionality.of(tester.element(find.text(value))),
        TextDirection.ltr,
        reason: value,
      );
    }

    await pumpWithPlate('ط ن ج 4821');
    expect(
      Directionality.of(tester.element(find.text('ط ن ج 4821'))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  /// A captain running the system font large is a real configuration, and the
  /// profile is the densest screen in the app — an avatar, name and rating pill
  /// on one toolbar row, then metric tiles and identity rows. It is the most
  /// likely place for an enlarged font to break a layout.
  for (final scale in [1.3, 1.6]) {
    testWidgets('profile holds at small @ textScale $scale', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          BlocProvider<DriverProfileCubit>(
            create: (_) => _StubProfileCubit(DriverProfileLoaded(_profile())),
            child: const DriverProfilePage(),
          ),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }

  /// The detail rows are the body of this screen, and they used to split each
  /// row 50/50 between the label and the value: both children carried `flex: 1`,
  /// so a value was capped at half the row no matter how short its label was.
  /// A licence number then lost its tail to an ellipsis while empty space sat
  /// beside a three-letter label — and a truncated identifier is a *different*
  /// number, not just a clipped one.
  ///
  /// These assert the shape that replaced it: the value takes only the width it
  /// needs, every value lines up on the row's trailing edge, and a long one is
  /// bounded rather than allowed to run over the label.
  group('label → value rows', () {
    /// Every `CaptainListRow` value on the screen, paired with its rect. The
    /// app runs RTL, so a row's trailing edge is its **left** edge.
    Map<String, Rect> valueRects(WidgetTester tester) {
      const values = [
        '01001234567', // phone
        'EMP-2201', // captain code
        'BUS-104', // vehicle code
      ];
      return {
        for (final value in values)
          if (find.text(value).evaluate().isNotEmpty)
            value: tester.getRect(find.text(value)),
      };
    }

    testWidgets('values of different lengths share one trailing column', (
      tester,
    ) async {
      // Tall enough that every group is laid out without scrolling.
      tester.view.physicalSize = const Size(390, 2000);
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

      final rects = valueRects(tester);
      expect(rects, hasLength(3), reason: 'all three value rows should render');

      final edges = rects.values.map((rect) => rect.left).toSet();
      expect(
        edges,
        hasLength(1),
        reason:
            'an 11-digit phone number and a 7-character vehicle code must '
            'still start at the same trailing edge: $rects',
      );

      // The lengths genuinely differ — otherwise the assertion above would
      // hold for a layout that had gone back to fixed-width columns.
      final widths = rects.values.map((rect) => rect.width).toSet();
      expect(widths, hasLength(greaterThan(1)));
    });

    testWidgets('a value never runs over its label', (tester) async {
      tester.view.physicalSize = const Size(320, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          BlocProvider<DriverProfileCubit>(
            create: (_) => _StubProfileCubit(
              DriverProfileLoaded(
                _profile(
                  // Longer than anything the fleet actually issues, on the
                  // narrowest phone the app supports.
                  license: '2981234567890123456789',
                  model: 'Mercedes Benz Sprinter 519 CDI Tourer Extra Long',
                ),
              ),
            ),
            child: const DriverProfilePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final pair in {
        'رقم الرخصة': '2981234567890123456789',
        'الموديل': 'Mercedes Benz Sprinter 519 CDI Tourer Extra Long',
      }.entries) {
        final label = tester.getRect(find.text(pair.key));
        final value = tester.getRect(find.text(pair.value));
        expect(
          value.right,
          lessThanOrEqualTo(label.left),
          reason: '"${pair.key}" and its value overlap',
        );
        expect(label.width, greaterThan(0), reason: pair.key);
      }

      expect(tester.takeException(), isNull);
    });
  });

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
