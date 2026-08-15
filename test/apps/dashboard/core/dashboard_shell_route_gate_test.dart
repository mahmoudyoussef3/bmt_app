import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_permission.dart';
import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
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

/// The console renders more routes than the sidebar lists — السائقون, المركبات,
/// مراجعة المدفوعات and friends are drilled into from cards on Home rather than
/// navigated to. Those routes were absent from the shell's item table, and the
/// table's lookup resolved a miss to `_items.first`: the home item, which
/// carries no permission and therefore permits everyone.
///
/// The consequence was concrete. A support agent — a role whose permission set
/// deliberately excludes fleet — could tap the السائقون tile on the home screen
/// and land inside the full fleet module, where `drivers` rows carry phone
/// numbers, national ids and licence data. RLS scopes those rows to the office
/// but does not discriminate by role, so this client-side gate was the only one
/// there was.
///
/// These tests hold both halves of the fix: the gate refuses what the role does
/// not permit, and the top bar can still name every route the shell can open.
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

OfficeContext _office(DashboardRole role) => OfficeContext(
  officeId: 'office-1',
  officeName: 'مكتب النيل',
  officeSlug: 'nile',
  role: role,
  username: 'nile.user',
  fullName: 'محمود',
);

Widget _shell(DashboardRole role, {String? initialRoute}) {
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
      home: DashboardShell(office: _office(role), initialRoute: initialRoute),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  DashboardRole role, {
  String? initialRoute,
}) async {
  tester.view.physicalSize = const Size(1600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_shell(role, initialRoute: initialRoute));
  await tester.pump();
}

void main() {
  setUp(() {
    dashboardDi
      ..registerFactory<DashboardHomeCubit>(_FakeHomeCubit.new)
      ..registerFactory<OperationalAlertsCubit>(_FakeAlertsCubit.new)
      ..registerLazySingleton<OperationalAlertsBadgeCubit>(_FakeBadgeCubit.new);
  });

  tearDown(() => dashboardDi.reset());

  test('the permission model still withholds fleet from support agents', () {
    // If this ever changes, the widget test below is testing nothing.
    for (final permission in [
      DashboardPermission.fleet,
      DashboardPermission.drivers,
      DashboardPermission.vehicles,
      DashboardPermission.assignments,
    ]) {
      expect(
        DashboardPermissions.canAccess(DashboardRole.supportAgent, permission),
        isFalse,
        reason: '$permission must stay closed to support agents',
      );
      expect(
        DashboardPermissions.canAccess(DashboardRole.admin, permission),
        isTrue,
      );
    }
  });

  testWidgets('the top bar can name every route the shell can render', (
    tester,
  ) async {
    await _pump(tester, DashboardRole.admin);
    final shell = tester.state(find.byType(DashboardShell)) as dynamic;

    // Reports, payment verification, drivers and vehicles all rendered under
    // the title "الرئيسية" because the lookup fell back to the home item.
    const expected = {
      DashboardRoutes.reports: 'التقارير',
      DashboardRoutes.paymentVerification: 'مراجعة المدفوعات',
      DashboardRoutes.drivers: 'السائقون',
      DashboardRoutes.vehicles: 'المركبات',
      DashboardRoutes.assignments: 'مهام الأسطول',
      DashboardRoutes.users: 'المستخدمون والصلاحيات',
      DashboardRoutes.referrals: 'برنامج الإحالة',
    };

    for (final entry in expected.entries) {
      // ignore: avoid_dynamic_calls
      expect(
        shell.titleForRouteForTest(entry.key),
        entry.value,
        reason: '${entry.key} should title itself',
      );
    }
  });

  testWidgets('an unlisted route is refused rather than silently allowed', (
    tester,
  ) async {
    await _pump(tester, DashboardRole.admin);
    final shell = tester.state(find.byType(DashboardShell)) as dynamic;

    // ignore: avoid_dynamic_calls
    expect(shell.canOpenRouteForTest(DashboardRoutes.trips), isTrue);
    // ignore: avoid_dynamic_calls
    expect(shell.canOpenRouteForTest('/not-a-route'), isFalse);
  });

  testWidgets('a support agent cannot reach the fleet module by any route', (
    tester,
  ) async {
    await _pump(tester, DashboardRole.supportAgent);
    final shell = tester.state(find.byType(DashboardShell)) as dynamic;

    // The sidebar row was already refused; these three were the way around it.
    for (final route in [
      DashboardRoutes.fleet,
      DashboardRoutes.drivers,
      DashboardRoutes.vehicles,
      DashboardRoutes.assignments,
    ]) {
      // ignore: avoid_dynamic_calls
      expect(
        shell.canOpenRouteForTest(route),
        isFalse,
        reason: '$route must stay closed to a support agent',
      );
    }

    // And the queues the role does own are still open, so the gate is a gate
    // and not a wall.
    for (final route in [
      DashboardRoutes.bookings,
      DashboardRoutes.tickets,
      DashboardRoutes.paymentVerification,
      DashboardRoutes.reports,
    ]) {
      // ignore: avoid_dynamic_calls
      expect(shell.canOpenRouteForTest(route), isTrue, reason: route);
    }
  });

  testWidgets('the platform console stays closed to an office owner', (
    tester,
  ) async {
    // `platformOnly` is checked against the authenticated identity, not the
    // switchable role — and the referral programme is platform-wide data with
    // no office_id, so it belongs behind that flag too.
    await _pump(tester, DashboardRole.admin);
    final shell = tester.state(find.byType(DashboardShell)) as dynamic;

    for (final route in [
      DashboardRoutes.referrals,
      DashboardRoutes.platformOffices,
      DashboardRoutes.platformCatalog,
      DashboardRoutes.platformLicenses,
      DashboardRoutes.platformBilling,
    ]) {
      // ignore: avoid_dynamic_calls
      expect(shell.canOpenRouteForTest(route), isFalse, reason: route);
    }
  });
}
