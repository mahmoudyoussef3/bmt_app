import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_seat_layout_visualizer.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicle_form_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/vehicle_seat_configuration.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/pending_fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';

/// Two things this module must get right that the rest of the dashboard must not:
/// the cabin drawing does **not** mirror under Arabic, and the vehicle form's
/// primary action stays reachable at every window size and text scale.

const _driver = FleetDriver(
  id: 'd-1',
  employeeCode: 'EMP-1',
  fullName: 'سائق تجريبي',
  phone: '01000000000',
  emergencyPhone: '',
  address: '',
  nationalId: '',
  profileImageUrl: '',
  licenseNumber: '',
  licenseExpiryDate: '',
  hireDate: '',
  notes: '',
  status: FleetDriverStatus.active,
);

const _workspace = FleetWorkspace(
  drivers: [_driver],
  vehicles: [],
  assignments: [],
  documents: [],
);

FleetVehicle _vehicle(VehicleType type) {
  final capacity = VehicleSeatConfigurator.capacityFor(type, 14);
  return FleetVehicle(
    id: 'v-1',
    // A deliberately long Arabic code and a long plate: the two strings most
    // likely to burst a row in this module.
    vehicleCode: 'حافلة النقل الجماعي رقم ٢٠١ - الخط السريع',
    plateNumber: '٣٣٠٠ ق ل م ن هـ',
    vehicleType: type.dbValue,
    brand: 'Toyota',
    model: type.dbValue,
    manufactureYear: 2022,
    color: 'أبيض',
    capacity: capacity,
    seatLayoutType: 'standard',
    imageUrl: '',
    notes: '',
    status: FleetVehicleStatus.active,
    currentDriverId: 'd-1',
    seatConfiguration: VehicleSeatConfigurator.resolve(
      type: type,
      capacity: capacity,
    ),
    licenseExpiry: '',
    insuranceExpiry: '',
    inspectionExpiry: '',
  );
}

Widget _rtl(Widget child, {double textScale = 1.0}) {
  return MaterialApp(
    theme: DashboardAppTheme.light(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('the cabin keeps its physical orientation under Arabic RTL', () {
    testWidgets('the Hiace driver bench stays on the left', (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final vehicle = _vehicle(VehicleType.hiace);
      await tester.pumpWidget(
        _rtl(
          SingleChildScrollView(
            child: FleetSeatLayoutVisualizer(
              seatConfig: vehicle.seatConfiguration,
              vehicleType: VehicleType.hiace,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Blueprint column 1 is the driver's side of a left-hand-drive vehicle.
      // Seat '1' sits on the far side of the aisle from it, in the last column.
      final driverIcon = tester.getCenter(
        find.byIcon(Icons.settings_accessibility_rounded).first,
      );
      final firstSeat = tester.getCenter(find.text('1'));

      expect(
        driverIcon.dx,
        lessThan(firstSeat.dx),
        reason: 'RTL must not move the steering wheel to the right-hand side',
      );
    });

    testWidgets('the Coaster door stays on the same side as its blueprint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final vehicle = _vehicle(VehicleType.coaster);
      await tester.pumpWidget(
        _rtl(
          SingleChildScrollView(
            child: FleetSeatLayoutVisualizer(
              seatConfig: vehicle.seatConfiguration,
              vehicleType: VehicleType.coaster,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Coaster row 1 is `D . | ^ S`: driver at column 1, entrance at column 4.
      final driverIcon = tester.getCenter(
        find.byIcon(Icons.settings_accessibility_rounded).first,
      );
      final door = tester.getCenter(find.byIcon(Icons.sensor_door_outlined));

      expect(
        driverIcon.dx,
        lessThan(door.dx),
        reason: 'the entrance is behind the driver, not in front of them',
      );
    });

    testWidgets('seat numbers still read in cabin order', (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final vehicle = _vehicle(VehicleType.hiace);
      await tester.pumpWidget(
        _rtl(
          SingleChildScrollView(
            child: FleetSeatLayoutVisualizer(
              seatConfig: vehicle.seatConfiguration,
              vehicleType: VehicleType.hiace,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Row 5 of the Hiace is a flush four-seat bench, labels 11..14 left to
      // right. Pinning the grid to LTR is what keeps that true.
      final positions = <String, double>{
        for (final label in const ['11', '12', '13', '14'])
          label: tester.getCenter(find.text(label)).dx,
      };

      expect(positions['11']!, lessThan(positions['12']!));
      expect(positions['12']!, lessThan(positions['13']!));
      expect(positions['13']!, lessThan(positions['14']!));
    });
  });

  group('the vehicle form stays usable at every size', () {
    // 1280 is a small laptop; 900 a narrow docked window; 1600 a wide desktop.
    for (final size in const [Size(900, 700), Size(1280, 800), Size(1600, 1000)]) {
      for (final scale in const [1.0, 1.3, 1.6]) {
        testWidgets(
          'save is on screen and nothing overflows @ ${size.width.toInt()}x'
          '${size.height.toInt()} scale $scale',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              _rtl(
                FleetVehicleFormView(
                  vehicle: _vehicle(VehicleType.coaster),
                  workspace: _workspace,
                  onBack: () {},
                  onUploadFile: (_, _, _) async => '',
                  onSave: (_, List<PendingFleetDocument> _) async => null,
                ),
                textScale: scale,
              ),
            );
            await tester.pumpAndSettle();

            expect(
              tester.takeException(),
              isNull,
              reason: 'layout overflowed at ${size.width}px, scale $scale',
            );

            // The docked action bar is the point: the primary action must be
            // within the viewport without scrolling past the seat map and the
            // whole document section to reach it.
            final saveBar = tester.getRect(find.byType(FleetFormActionsBar));
            expect(
              saveBar.bottom,
              lessThanOrEqualTo(size.height + 0.5),
              reason: 'the save bar fell below the fold',
            );
            expect(saveBar.top, greaterThanOrEqualTo(0));
            expect(find.text('حفظ التعديلات'), findsOneWidget);
          },
        );
      }
    }

    testWidgets('the actions bar drops its hint before it overflows', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _rtl(
          Center(
            child: SizedBox(
              width: 380,
              child: FleetFormActionsBar(
                saving: false,
                onCancel: () {},
                onSave: () {},
                saveLabel: 'حفظ التعديلات',
              ),
            ),
          ),
          textScale: 1.6,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('راجع البيانات قبل الحفظ النهائي.'), findsNothing);
      expect(find.text('حفظ التعديلات'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
    });
  });
}
