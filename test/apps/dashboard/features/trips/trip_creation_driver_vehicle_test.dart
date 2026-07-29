import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/features/trips/presentation/widgets/trip_creation_wizard.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/domain/entities/trip_driver_option.dart';

/// The trip planner's central rule, at the UI: the operator chooses a driver and the
/// system chooses the bus.
///
/// Everything here would have passed trivially before
/// 20260731090000_driver_vehicle_authority — the planner had a second dropdown listing
/// the whole fleet, and any driver could be paired with any bus in it. These are the
/// assertions that stop that dropdown from coming back.

const _hiace = AssignedVehicle(
  id: 'v-hiace',
  plateNumber: 'ABC 123',
  vehicleCode: 'VH-01',
  vehicleType: 'Hiace',
  brand: 'Toyota',
  model: 'Hiace',
  capacity: 14,
  status: 'active',
);

const _coaster = AssignedVehicle(
  id: 'v-coaster',
  // Deliberately long, in Arabic-Indic digits: the plate is the string most likely to
  // burst this card at a large text scale.
  plateNumber: '٣٣٠٠ ق ل م ن هـ',
  vehicleCode: 'VH-02',
  vehicleType: 'Coaster',
  brand: 'Toyota',
  model: 'Coaster',
  capacity: 30,
  status: 'active',
);

const _inMaintenance = AssignedVehicle(
  id: 'v-broken',
  plateNumber: 'XYZ 789',
  vehicleCode: 'VH-03',
  vehicleType: 'Hiace',
  brand: 'Toyota',
  model: 'Hiace',
  capacity: 14,
  status: 'maintenance',
);

const _ahmed = TripDriverOption(
  id: 'd-ahmed',
  name: 'أحمد محمد',
  phone: '01000000001',
  assignedVehicle: _hiace,
);

const _mona = TripDriverOption(
  id: 'd-mona',
  name: 'منى عبد الله',
  phone: '01000000002',
  assignedVehicle: _coaster,
);

const _unassigned = TripDriverOption(
  id: 'd-none',
  name: 'سائق بلا سيارة',
  phone: '01000000003',
);

const _brokenBus = TripDriverOption(
  id: 'd-broken',
  name: 'سائق سيارته معطلة',
  phone: '01000000004',
  assignedVehicle: _inMaintenance,
);

final _route = OperationRoute(
  id: 'r-1',
  name: 'بنها - القرية الذكية',
  startCity: 'بنها',
  endCity: 'القرية الذكية',
  duration: 'ساعة',
  distance: '60 كم',
  status: OperationRouteStatus.active,
  stations: const [
    RouteStation(
      id: 'st-1',
      name: 'بنها',
      area: 'القليوبية',
      arrivalOffset: '0',
      departureOffset: '0',
      locationDescription: '',
      notes: '',
      order: 1,
    ),
  ],
  notes: const [],
);

Widget _harness(
  List<TripDriverOption> drivers, {
  double textScale = 1.0,
  ValueChanged<String>? onOpenModule,
}) {
  return MaterialApp(
    theme: DashboardAppTheme.light(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Builder(
        // copyWith, not a fresh MediaQueryData: the planner sizes its dialog from
        // MediaQuery.sizeOf, and replacing the whole thing would hand it Size.zero.
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: TripCreationWizard(
              routes: [_route],
              drivers: drivers,
              onOpenModule: onOpenModule,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Picks the driver named [name] from the planner's one and only resource dropdown.
Future<void> _selectDriver(WidgetTester tester, String name) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).last);
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining(name).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // The planner refreshes availability from its cubit on mount. There is no cubit in
    // this harness, so that call throws and is swallowed by its own catch — which is
    // the behaviour under test's precondition, not a failure.
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('TripCreationCubit')) return;
      FlutterError.presentError(details);
    };
  });

  group('trip creation asks for a driver, never for a vehicle', () {
    testWidgets(
      'there is exactly one resource dropdown, and it is the driver',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_harness(const [_ahmed, _mona]));
        await tester.pump();

        expect(find.text('اختر السائق'), findsOneWidget);
        expect(
          find.text('اختر المركبة'),
          findsNothing,
          reason: 'the vehicle dropdown must never come back',
        );
        // Route + driver. A third would mean a vehicle picker crept back in.
        expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
      },
    );

    testWidgets(
      'the assigned vehicle is shown read-only once a driver is picked',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_harness(const [_ahmed, _mona]));
        await tester.pump();

        expect(find.text('السيارة المخصصة للسائق'), findsOneWidget);
        expect(
          find.textContaining('اختر السائق أولاً'),
          findsOneWidget,
          reason: 'before a driver is chosen the card explains itself',
        );

        await _selectDriver(tester, 'أحمد محمد');

        expect(find.text('Toyota Hiace'), findsOneWidget);
        expect(find.text('ABC 123'), findsOneWidget);
        expect(find.text('14'), findsWidgets);
        expect(
          find.textContaining('سيتم استخدام السيارة المخصصة للسائق تلقائياً'),
          findsOneWidget,
        );
      },
    );

    testWidgets('changing the driver changes the derived vehicle', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness(const [_ahmed, _mona]));
      await tester.pump();

      await _selectDriver(tester, 'أحمد محمد');
      expect(find.text('ABC 123'), findsOneWidget);
      expect(find.text('٣٣٠٠ ق ل م ن هـ'), findsNothing);

      await _selectDriver(tester, 'منى عبد الله');
      expect(find.text('٣٣٠٠ ق ل م ن هـ'), findsOneWidget);
      expect(find.text('ABC 123'), findsNothing);
      expect(
        find.text('30'),
        findsWidgets,
        reason: 'the seat count follows the bus, not the last selection',
      );
    });

    testWidgets('a driver with no vehicle blocks creation and says why', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var openedModule = '';
      await tester.pumpWidget(
        _harness(const [
          _unassigned,
        ], onOpenModule: (route) => openedModule = route),
      );
      await tester.pump();

      await _selectDriver(tester, 'سائق بلا سيارة');

      expect(find.text('هذا السائق غير مرتبط بسيارة حالياً'), findsOneWidget);
      expect(find.text('تعيين سيارة للسائق'), findsOneWidget);
      expect(
        find.text('حدث خطأ'),
        findsNothing,
        reason: 'the blocked state must name its cause, never a generic error',
      );

      final submit = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('إنشاء الرحلة'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(submit.onPressed, isNull);

      await tester.tap(find.text('تعيين سيارة للسائق'));
      await tester.pumpAndSettle();
      expect(openedModule, '/assignments');
    });

    testWidgets('a driver whose bus is in maintenance is refused too', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness(const [_ahmed, _brokenBus]));
      await tester.pump();

      // The option itself is disabled, so the operator is stopped before selecting.
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      expect(find.textContaining('سيارته XYZ 789 غير متاحة'), findsOneWidget);
    });
  });

  group('the derived vehicle card survives large text', () {
    for (final scale in const [1.0, 1.3, 1.6]) {
      testWidgets('no overflow at ${scale}x text scale', (tester) async {
        tester.view.physicalSize = const Size(1000, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _harness(const [_mona, _unassigned], textScale: scale),
        );
        await tester.pump();

        await _selectDriver(tester, 'منى عبد الله');

        expect(tester.takeException(), isNull);
      });
    }
  });
}
