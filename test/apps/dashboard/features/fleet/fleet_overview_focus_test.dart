import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/screens/fleet_overview_screen.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';

/// Opening a driver flips the overview screen from a scrolling page to a
/// bounded split view. That flip must not throw the drivers tab away: when it
/// did, the tab came back in list mode inside a box with no scroll of its own
/// and the whole list overflowed the viewport.

FleetDriver _driver(String id) => FleetDriver(
  id: id,
  employeeCode: 'EMP-$id',
  fullName: 'سائق $id',
  phone: '0100000000$id',
  emergencyPhone: '',
  address: '',
  nationalId: '',
  profileImageUrl: '',
  licenseNumber: '',
  licenseExpiryDate: '2027-07-12',
  hireDate: '',
  notes: '',
  status: FleetDriverStatus.active,
);

final _workspace = FleetWorkspace(
  drivers: List.generate(8, (i) => _driver('${i + 1}')),
  vehicles: const [],
  assignments: const [],
  documents: const [],
);

class _FakeOverview extends Cubit<FleetOverviewState>
    implements FleetOverviewCubit {
  _FakeOverview() : super(FleetOverviewLoaded(_workspace));

  @override
  Future<void> loadWorkspace() async {}

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeDrivers extends Cubit<FleetDriversState>
    implements FleetDriversCubit {
  _FakeDrivers() : super(FleetDriversLoaded(drivers: _workspace.drivers));

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeDocuments extends Cubit<FleetDocumentsState>
    implements FleetDocumentsCubit {
  _FakeDocuments() : super(const FleetDocumentsLoaded(documents: []));

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeVehicles extends Cubit<FleetVehiclesState>
    implements FleetVehiclesCubit {
  _FakeVehicles() : super(const FleetVehiclesLoaded(vehicles: []));

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

Widget _harness() {
  return MaterialApp(
    theme: DashboardAppTheme.light(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: BlocProvider<FleetOverviewCubit>(
          create: (_) => _FakeOverview(),
          // The console shell hands every module a bounded box, never an
          // infinite one — reproduce that, or the overflow cannot happen.
          child: const FleetOverviewScreen(),
        ),
      ),
    ),
  );
}

/// Opens the first driver through whichever affordance the current width
/// renders.
///
/// The drivers tab swaps between a card list and [OpsDataTable] on its own
/// breakpoint, and this test is about what the *flip to split view* does to the
/// tab — not about which of the two the width happened to pick. Naming one
/// layout's button made the test fail the next time the breakpoint moved, while
/// the behaviour under test was still correct.
Future<void> _openFirstDriver(WidgetTester tester) async {
  final card = find.widgetWithText(FilledButton, 'فتح الملف');
  final table = find.byTooltip('عرض جاهزية السائق');
  final target = tester.any(card) ? card.first : table.first;

  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    dashboardDi
      ..registerFactory<FleetDriversCubit>(_FakeDrivers.new)
      ..registerFactory<FleetDocumentsCubit>(_FakeDocuments.new)
      ..registerFactory<FleetVehiclesCubit>(_FakeVehicles.new);
  });

  tearDown(() => dashboardDi.reset());

  testWidgets('opening a driver keeps the tab alive instead of overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await _openFirstDriver(tester);

    expect(tester.takeException(), isNull);
    // The detail pane is open, not a second copy of the list.
    expect(find.text('ملف السائق: سائق 1'), findsOneWidget);
  });

  testWidgets('closing the driver gives the page its scroll back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await _openFirstDriver(tester);

    await tester.tap(find.text('إدارة الأسطول').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ملف السائق: سائق 1'), findsNothing);
    // The module chrome is back, which only the scrolling page renders.
    expect(find.text('إدارة الأسطول'), findsOneWidget);
  });

  testWidgets('re-opening a tab immediately does not clash on its key', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Deliberately without settling in between: each tab holds a global key,
    // and two live elements may never claim the same one.
    await tester.tap(find.text('المركبات').first);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.text('السائقون').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The drivers tab rebuilt and is listing again, in whichever layout the
    // width calls for.
    expect(find.text('سائق 1'), findsWidgets);
  });
}
