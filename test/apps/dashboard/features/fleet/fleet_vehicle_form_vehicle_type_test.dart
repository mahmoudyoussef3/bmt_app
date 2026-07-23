import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicle_form_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/pending_fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/vehicle_seat_configuration.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';

/// The operator-facing behaviour: pick a vehicle type and the capacity and the
/// seat map follow it, on create and on edit, without the two ever mixing.
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
    vehicleCode: 'BUS-201',
    plateNumber: '٣٣٠٠ ق ل',
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

Future<FleetVehicle?> Function() _pump(
  WidgetTester tester, {
  FleetVehicle? vehicle,
}) {
  FleetVehicle? saved;

  return () async {
    await tester.binding.setSurfaceSize(const Size(1400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: FleetVehicleFormView(
          vehicle: vehicle,
          workspace: _workspace,
          onBack: () {},
          onUploadFile: (_, _, _) async => '',
          onSave: (v, List<PendingFleetDocument> _) async {
            saved = v;
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return saved;
  };
}

/// Reads the value of the capacity field ("السعة الركابية").
String _capacityValue(WidgetTester tester) {
  final field = tester.widget<TextFormField>(
    find.ancestor(
      of: find.text('السعة الركابية'),
      matching: find.byType(TextFormField),
    ),
  );
  return field.controller!.text;
}

Future<void> _selectType(WidgetTester tester, VehicleType type) async {
  await tester.tap(find.text('نوع المركبة').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(VehicleSeatConfigurator.typeLabels[type]!).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a new vehicle defaults to Coaster with its own capacity', (
    tester,
  ) async {
    await _pump(tester)();

    expect(find.text('السعة الركابية'), findsOneWidget);
    expect(_capacityValue(tester), '30');
  });

  testWidgets('selecting Hiace switches the capacity to 14', (tester) async {
    await _pump(tester)();

    await _selectType(tester, VehicleType.hiace);

    expect(_capacityValue(tester), '14');
  });

  testWidgets('selecting Toyota Coaster switches the capacity to 30', (
    tester,
  ) async {
    await _pump(tester)();

    await _selectType(tester, VehicleType.hiace);
    expect(_capacityValue(tester), '14');

    await _selectType(tester, VehicleType.coaster);
    expect(_capacityValue(tester), '30');
  });

  testWidgets('the layout preview redraws when the type changes', (
    tester,
  ) async {
    await _pump(tester)();

    // The Coaster cabin is the only one with an entrance door.
    expect(find.byIcon(Icons.sensor_door_outlined), findsOneWidget);

    await _selectType(tester, VehicleType.hiace);
    expect(find.byIcon(Icons.sensor_door_outlined), findsNothing);

    await _selectType(tester, VehicleType.coaster);
    expect(find.byIcon(Icons.sensor_door_outlined), findsOneWidget);
  });

  testWidgets('a type without a blueprint leaves the capacity to the owner', (
    tester,
  ) async {
    await _pump(tester)();

    await _selectType(tester, VehicleType.h1);

    final field = tester.widget<TextFormField>(
      find.ancestor(
        of: find.text('السعة الركابية'),
        matching: find.byType(TextFormField),
      ),
    );
    expect(field.controller!.text, '30', reason: 'keeps the last value');
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byWidget(field),
              matching: find.byType(TextField),
            ),
          )
          .readOnly,
      isFalse,
    );
  });

  testWidgets('editing a Hiace opens on Hiace with 14 seats', (tester) async {
    await _pump(tester, vehicle: _vehicle(VehicleType.hiace))();

    expect(
      find.text(VehicleSeatConfigurator.typeLabels[VehicleType.hiace]!),
      findsOneWidget,
    );
    expect(_capacityValue(tester), '14');
    expect(find.byIcon(Icons.sensor_door_outlined), findsNothing);
  });

  testWidgets('editing a Coaster opens on Coaster with 30 seats', (
    tester,
  ) async {
    await _pump(tester, vehicle: _vehicle(VehicleType.coaster))();

    expect(
      find.text(VehicleSeatConfigurator.typeLabels[VehicleType.coaster]!),
      findsOneWidget,
    );
    expect(_capacityValue(tester), '30');
    expect(find.byIcon(Icons.sensor_door_outlined), findsOneWidget);
  });

  testWidgets('saving a Coaster persists 30 Coaster seats', (tester) async {
    final result = _pump(tester, vehicle: _vehicle(VehicleType.hiace));
    await result();

    await _selectType(tester, VehicleType.coaster);
    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pumpAndSettle();

    final saved = await result();
    expect(saved, isNotNull);
    expect(saved!.vehicleType, 'Coaster');
    expect(saved.capacity, 30);

    final passengers = saved.seatConfiguration.seats
        .where((s) => s.seatType == 'passenger')
        .toList();
    expect(passengers, hasLength(30));
    expect(
      {for (final s in passengers) s.seatNumber},
      hasLength(30),
      reason: 'switching type must not duplicate seats',
    );
  });

  testWidgets('saving an unchanged Hiace keeps 14 Hiace seats', (
    tester,
  ) async {
    final result = _pump(tester, vehicle: _vehicle(VehicleType.hiace));
    await result();

    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pumpAndSettle();

    final saved = await result();
    expect(saved, isNotNull);
    expect(saved!.vehicleType, 'Hiace');
    expect(saved.capacity, 14);
    expect(
      saved.seatConfiguration.seats.where((s) => s.seatType == 'passenger'),
      hasLength(14),
    );
  });
}
