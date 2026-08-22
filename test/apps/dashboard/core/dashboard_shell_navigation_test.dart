import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/core/routes/dashboard_shell.dart';
import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
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

/// The shell mounts real module cubits through `dashboardDi`. Only the two the
/// home route needs are faked here — the point of these tests is the frame
/// (navigation, rail, identity, sign-out), not what the modules render inside
/// it.
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

class _FakeBadgeCubit extends Cubit<int>
    implements OperationalAlertsBadgeCubit {
  _FakeBadgeCubit() : super(0);
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
  officeName: 'مكتب النيل',
  officeSlug: 'nile',
  role: DashboardRole.admin,
  username: 'nile.admin',
  fullName: 'محمود',
);

Widget _shell() {
  return BlocProvider(
    create: (_) => DashboardThemeCubit(
      DashboardThemeRepository(storage: _MemorySecureStorage()),
    ),
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const DashboardShell(office: _office),
    ),
  );
}

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_shell());
  await tester.pump();
  // A second `_pumpAt` in the same test reuses the (unkeyed) sidebar's State
  // rather than remounting it, so the rail↔full-width `AnimatedContainer`
  // genuinely animates instead of snapping to its new value — settle it, or a
  // tap right after lands on content still clipped by the old, narrower width.
  await tester.pump(const Duration(milliseconds: 250));
}

/// The sidebar is an accordion — only one group's items are built at a time —
/// so a test after anything but the home route's own (group-less) items has to
/// open that item's group first, the same way an operator would.
Future<void> _expandGroup(WidgetTester tester, String groupLabel) async {
  await tester.tap(find.text(groupLabel));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() {
    dashboardDi
      ..registerFactory<DashboardHomeCubit>(_FakeHomeCubit.new)
      ..registerFactory<OperationalAlertsCubit>(_FakeAlertsCubit.new)
      ..registerLazySingleton<OperationalAlertsBadgeCubit>(_FakeBadgeCubit.new);
  });

  tearDown(() => dashboardDi.reset());

  testWidgets('groups navigation into sections and names the office', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1600, 1400));

    // Section headers an owner should see, in the order the sidebar declares.
    for (final group in ['التشغيل', 'المبيعات', 'الأسطول', 'المالية']) {
      expect(find.text(group), findsOneWidget, reason: 'missing group $group');
    }

    // No section may share its name with an item inside it: "المالية" the
    // group, "المدفوعات" the screen — opened, since the accordion starts with
    // every group but the active route's own closed.
    await _expandGroup(tester, 'المالية');
    expect(find.text('المدفوعات'), findsOneWidget);
    expect(find.text('مكتب النيل'), findsOneWidget);
  });

  testWidgets('signed-in operator and sign-out live in the sidebar footer', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1600, 1400));

    expect(find.text('محمود'), findsOneWidget);
    expect(find.text(DashboardRole.admin.label), findsWidgets);

    final signOut = find.byTooltip('تسجيل الخروج');
    expect(signOut, findsOneWidget);

    await tester.tap(signOut);
    await tester.pump(const Duration(milliseconds: 400));

    // Confirms before ending the session — never a one-tap logout.
    expect(find.text('هل تريد إنهاء جلستك الحالية؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('collapsing the sidebar keeps every item reachable by tooltip', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1600, 1400));
    await _expandGroup(tester, 'التشغيل');

    expect(find.text('الرحلات'), findsOneWidget);

    await tester.tap(find.byTooltip('طيّ القائمة'));
    await tester.pump(const Duration(milliseconds: 400));

    // Labels are gone, but nothing became a guess: each icon carries its label
    // as a tooltip, and the toggle back is still there.
    expect(find.text('الرحلات'), findsNothing);
    expect(find.byTooltip('الرحلات'), findsOneWidget);
    expect(find.byTooltip('توسيع القائمة'), findsOneWidget);
  });

  testWidgets('laptop widths open on the icon rail, desktops on full labels', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1000, 1200));
    expect(find.text('الرحلات'), findsNothing);
    expect(find.byTooltip('الرحلات'), findsOneWidget);

    await _pumpAt(tester, const Size(1600, 1200));
    await _expandGroup(tester, 'التشغيل');
    expect(find.text('الرحلات'), findsOneWidget);
  });

  testWidgets('narrow widths move navigation into a drawer with labels', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(700, 1200));

    expect(find.text('الرحلات'), findsNothing);
    await tester.tap(find.byTooltip('القائمة'));
    // The drawer slides in from the trailing edge (RTL: the right, off past
    // the 700px viewport) — `find.text` would still see it mid-slide since the
    // child is always built, but the group-header tap below needs it actually
    // on screen, so this settles the full slide before that happens.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await _expandGroup(tester, 'التشغيل');

    expect(find.text('الرحلات'), findsOneWidget);
  });

  testWidgets('the top bar names the section the open module belongs to', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1600, 1400));

    // Home belongs to no section, so the top bar shows only its title.
    expect(tester.widget<Text>(find.byKey(topBarTitleKey)).data, 'الرئيسية');
    expect(find.byKey(topBarSubtitleKey), findsNothing);

    // Settings, because it is the one module in the shell that mounts without
    // a feature cubit — this test is about the frame, not about Settings.
    await _expandGroup(tester, 'النظام');
    await tester.tap(find.text('الإعدادات'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.widget<Text>(find.byKey(topBarTitleKey)).data, 'الإعدادات');
    expect(tester.widget<Text>(find.byKey(topBarSubtitleKey)).data, 'النظام');
  });
}
