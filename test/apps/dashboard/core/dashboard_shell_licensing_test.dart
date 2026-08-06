import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/entitlements/entitlement_context.dart';
import 'package:bmt_app/apps/dashboard/core/entitlements/entitlement_service.dart';
import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/core/routes/dashboard_shell.dart';
import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
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

/// The licensing axis of the sidebar: hidden vs **locked** vs open (§10.2).
///
/// The distinction is commercial, not cosmetic. Hiding a module the office
/// could buy makes it unsellable — an owner cannot ask for something they have
/// never seen — while showing one it cannot buy is noise. So the shell draws
/// the purchasable ones locked, and the tap opens the upgrade card instead of a
/// dead-end "ليس لديك صلاحية", which is a different predicate's answer.

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

/// Serves a fixed document and never touches the network.
///
/// Implemented rather than subclassed — the same choice the module cubits above
/// make — because constructing a real `SupabaseClient` starts GoTrue's
/// auto-refresh, and the zero-duration timer it schedules outlives
/// `stopAutoRefresh()` and fails the test as a pending timer.
class _FakeEntitlements with ChangeNotifier implements EntitlementService {
  _FakeEntitlements(this._fixed);

  final EntitlementContext _fixed;

  @override
  EntitlementContext get context => _fixed;

  @override
  bool get isLoaded => _fixed.isLoaded;

  @override
  Future<void> load() async {}

  @override
  Future<void> refresh() async {}

  @override
  void clear() {}
}

EntitlementContext _entitlements({
  required Map<String, Map<String, dynamic>> features,
  String mode = 'enforcing',
}) {
  return EntitlementContext.fromRpc({
    'license': const {
      'plan_key': 'starter',
      'plan_name_ar': 'الأساسية',
      'status': 'active',
    },
    'features': features,
    'enforcement_mode': mode,
    'resolved_at': DateTime.now().toIso8601String(),
  });
}

/// `wallet` off but sellable ⇒ locked. `live_ops_center` off and not sellable
/// ⇒ hidden. Everything absent from the map resolves permissively.
Map<String, Map<String, dynamic>> get _walletLockedFleetHidden => {
  'wallet': {
    'value': false,
    'source': 'plan',
    'value_type': 'boolean',
    'name_ar': 'محفظة العملاء',
    'is_public': true,
    'enforcement_status': 'enforced',
  },
  'live_ops_center': {
    'value': false,
    'source': 'plan',
    'value_type': 'boolean',
    'name_ar': 'العمليات المباشرة',
    'is_public': false,
    'enforcement_status': 'enforced',
  },
};

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

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_shell());
  await tester.pump();
}

void _registerShellDeps() {
  dashboardDi
    ..registerFactory<DashboardHomeCubit>(_FakeHomeCubit.new)
    ..registerFactory<OperationalAlertsCubit>(_FakeAlertsCubit.new)
    ..registerLazySingleton<OperationalAlertsBadgeCubit>(_FakeBadgeCubit.new);
}

void main() {
  tearDown(() => dashboardDi.reset());

  testWidgets('a purchasable module stays in the sidebar, wearing a lock', (
    tester,
  ) async {
    _registerShellDeps();
    dashboardDi.registerLazySingleton<EntitlementService>(
      () =>
          _FakeEntitlements(_entitlements(features: _walletLockedFleetHidden)),
    );

    await _pump(tester);

    // Sellable and unowned: visible, so the owner can discover and ask for it.
    expect(find.text('محفظة العملاء'), findsOneWidget);
    // Unsellable and unowned: gone entirely — an upgrade prompt for something
    // the office cannot buy is noise.
    expect(find.text('العمليات المباشرة'), findsNothing);
    // Untouched by licensing.
    expect(find.text('الرحلات'), findsOneWidget);
    // And it is visibly locked, not silently inert.
    expect(find.byIcon(DashboardIcons.locked), findsOneWidget);
  });

  testWidgets('tapping a locked module explains the plan, not the permission', (
    tester,
  ) async {
    _registerShellDeps();
    dashboardDi.registerLazySingleton<EntitlementService>(
      () =>
          _FakeEntitlements(_entitlements(features: _walletLockedFleetHidden)),
    );

    await _pump(tester);
    await tester.tap(find.text('محفظة العملاء'));
    // Not pumpAndSettle: the home screen behind the dialog holds a loading
    // shimmer that never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The upgrade card, naming the feature and the plan it sits behind.
    expect(find.text('ميزة غير متاحة في باقتك'), findsOneWidget);
    expect(find.text('الأساسية'), findsOneWidget);
    // Emphatically NOT the role refusal: a wrong answer here sends the owner to
    // hunt for a permission that was never the problem.
    expect(find.textContaining('ليس لديك صلاحية'), findsNothing);
  });

  testWidgets('while enforcement is off nothing is locked or hidden', (
    tester,
  ) async {
    _registerShellDeps();
    dashboardDi.registerLazySingleton<EntitlementService>(
      () => _FakeEntitlements(
        _entitlements(features: _walletLockedFleetHidden, mode: 'off'),
      ),
    );

    await _pump(tester);

    // Deploy day: the server serves everything, so the sidebar shows
    // everything, and no row wears a lock it would have to explain.
    expect(find.text('محفظة العملاء'), findsOneWidget);
    expect(find.text('العمليات المباشرة'), findsOneWidget);
    expect(find.byIcon(DashboardIcons.locked), findsNothing);
  });

  testWidgets('with no entitlement service registered the console is whole', (
    tester,
  ) async {
    // The failing-open default. A test harness, or a network blip on a real
    // sign-in, must never be what decides an operator has lost half their
    // console — the server is the boundary, this axis is only a hint.
    _registerShellDeps();

    await _pump(tester);

    expect(find.text('محفظة العملاء'), findsOneWidget);
    expect(find.text('العمليات المباشرة'), findsOneWidget);
    expect(find.byIcon(DashboardIcons.locked), findsNothing);
  });
}
