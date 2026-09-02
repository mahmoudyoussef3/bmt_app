/// Visual QA harness for the console's navigation — the docked sidebar, the
/// icon rail it collapses to, and the drawer it becomes on a narrow window.
///
/// Not a test of behaviour and deliberately not part of the suite's assertions:
/// run it with `--update-goldens` and look at the PNGs it writes to
/// `_captures/`.
///
///     flutter test test/apps/dashboard/core/dashboard_sidebar_visual_capture.dart --update-goldens
///
/// Typesets with the **real** [DashboardAppTheme] by registering a host Arabic
/// face under the family names google_fonts asks for (`Cairo_regular`, falling
/// back to `Cairo`); without it every glyph draws as a box.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/core/routes/dashboard_shell.dart';
import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_theme_cubit.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_theme_repository.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/cubit/dashboard_home_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/cubit/dashboard_home_state.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/domain/entities/operational_alert.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_badge_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_state.dart';
import 'package:bmt_app/core/security/secure_storage.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

class _FakeHomeCubit extends Cubit<DashboardHomeState>
    implements DashboardHomeCubit {
  _FakeHomeCubit() : super(const DashboardHomeLoading());

  @override
  Future<void> load() async {}
}

class _FakeAlertsCubit extends Cubit<OperationalAlertsState>
    implements OperationalAlertsCubit {
  _FakeAlertsCubit() : super(const OperationalAlertsInitial());

  @override
  void filterByType(OperationalAlertType? type) {}

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> markAsRead(String id) async {}

  @override
  void startWatching() {}
}

/// Seeded with a real count so the capture shows the nav badge, which is the
/// only element here that never appears in an empty console.
class _FakeBadgeCubit extends Cubit<int>
    implements OperationalAlertsBadgeCubit {
  _FakeBadgeCubit() : super(7);
}

class _MemorySecureStorage implements SecureStorage {
  final _values = <String, String>{};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

const _office = OfficeContext(
  officeId: 'office-1',
  officeName: 'مكتب النيل للنقل',
  officeSlug: 'nile',
  role: DashboardRole.admin,
  username: 'nile.admin',
  fullName: 'محمود يوسف',
  listingStatus: 'listed',
);

void main() {
  late ThemeData light;
  late ThemeData dark;

  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (file.existsSync()) {
      final bytes = ByteData.sublistView(file.readAsBytesSync());
      for (final family in const ['Cairo_regular', 'Cairo']) {
        await (FontLoader(family)..addFont(Future.value(bytes))).load();
      }
    }

    await runZonedGuarded(() async {
      light = DashboardAppTheme.light();
      dark = DashboardAppTheme.dark();
    }, (_, _) {});
  });

  setUp(() {
    dashboardDi
      ..registerFactory<DashboardHomeCubit>(_FakeHomeCubit.new)
      ..registerFactory<OperationalAlertsCubit>(_FakeAlertsCubit.new)
      ..registerLazySingleton<OperationalAlertsBadgeCubit>(_FakeBadgeCubit.new);
  });

  tearDown(() => dashboardDi.reset());

  testWidgets('docked sidebar — light', (tester) async {
    await _capture(tester, 'sidebar_1_docked_light', theme: light);
  });

  testWidgets('docked sidebar — dark', (tester) async {
    await _capture(tester, 'sidebar_2_docked_dark', theme: dark);
  });

  testWidgets('icon rail — laptop width', (tester) async {
    await _capture(
      tester,
      'sidebar_3_rail_light',
      theme: light,
      size: const Size(1000, 900),
    );
  });

  testWidgets('drawer — narrow window', (tester) async {
    await _capture(
      tester,
      'sidebar_4_drawer_light',
      theme: light,
      size: const Size(760, 900),
      openDrawer: true,
    );
  });

  testWidgets('drawer — dark', (tester) async {
    await _capture(
      tester,
      'sidebar_5_drawer_dark',
      theme: dark,
      size: const Size(760, 900),
      openDrawer: true,
    );
  });

  testWidgets('search filtering the list', (tester) async {
    await _capture(
      tester,
      'sidebar_6_search_light',
      theme: light,
      search: 'الم',
    );
  });

  testWidgets('search matching nothing', (tester) async {
    await _capture(
      tester,
      'sidebar_7_search_empty_light',
      theme: light,
      search: 'زززز',
    );
  });
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required ThemeData theme,
  Size size = const Size(1440, 900),
  bool openDrawer = false,
  String? search,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => DashboardThemeCubit(
        DashboardThemeRepository(storage: _MemorySecureStorage()),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: RepaintBoundary(key: key, child: child!),
        ),
        home: const DashboardShell(office: _office),
      ),
    ),
  );
  // The home module is a fake stuck on loading, and a shimmer would never let
  // `pumpAndSettle` return — step the frames by hand instead.
  await _settle(tester);

  if (openDrawer) {
    await tester.tap(find.byTooltip('القائمة'));
    await _settle(tester);
  }

  if (search != null) {
    await tester.enterText(find.byType(TextField).first, search);
    await _settle(tester);
  }

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}
