/// Visual QA harness for the driver and vehicle create/edit forms — not a
/// behaviour test. Run with `--update-goldens` and *look* at the PNGs in
/// `_captures/`:
///
///     flutter test test/apps/dashboard/features/fleet/fleet_forms_visual_capture.dart --update-goldens
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/theme/app_light_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/colors.dart';

import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_driver_form_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicle_form_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/pending_fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/vehicle_seat_configuration.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';

const _captureFont = 'CaptureArabic';

const _driver = FleetDriver(
  id: 'd-1',
  employeeCode: 'EMP-102',
  fullName: 'أحمد محمد السيد',
  phone: '01012345678',
  emergencyPhone: '01098765432',
  address: 'شارع الجمهورية، بنها، القليوبية',
  nationalId: '29001011234567',
  profileImageUrl: '',
  licenseNumber: 'DL-88213',
  licenseExpiryDate: '2027-05-01',
  hireDate: '2023-02-15',
  notes: '',
  status: FleetDriverStatus.active,
);

final _vehicle = FleetVehicle(
  id: 'v-1',
  vehicleCode: 'BUS-201',
  plateNumber: '٣٣٠٠ ق ل',
  vehicleType: VehicleType.coaster.dbValue,
  brand: 'Toyota',
  model: 'Coaster',
  manufactureYear: 2022,
  color: 'أبيض',
  capacity: VehicleSeatConfigurator.capacityFor(VehicleType.coaster, 30),
  seatLayoutType: 'standard',
  imageUrl: '',
  notes: '',
  status: FleetVehicleStatus.active,
  currentDriverId: 'd-1',
  seatConfiguration: VehicleSeatConfigurator.resolve(
    type: VehicleType.coaster,
    capacity: VehicleSeatConfigurator.capacityFor(VehicleType.coaster, 30),
  ),
  licenseExpiry: '',
  insuranceExpiry: '',
  inspectionExpiry: '',
);

const _workspace = FleetWorkspace(
  drivers: [_driver],
  vehicles: [],
  assignments: [],
  documents: [],
);

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(_captureFont)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  });

  testWidgets('driver form, new — light', (tester) async {
    await _captureDriver(tester, 'fleet_driver_1_new_light', driver: null);
  });

  testWidgets('driver form, submitted empty — light', (tester) async {
    await _captureDriver(
      tester,
      'fleet_driver_2_validation_light',
      driver: null,
      afterPump: (tester) async {
        await tester.tap(find.text('حفظ السائق'));
        // The error-state border/text is an implicit InputDecorator
        // animation; a bare pump() catches it mid-fade.
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('driver form, editing — light', (tester) async {
    await _captureDriver(
      tester,
      'fleet_driver_3_editing_light',
      driver: _driver,
    );
  });

  testWidgets('vehicle form, new — light', (tester) async {
    await _captureVehicle(tester, 'fleet_vehicle_1_new_light', vehicle: null);
  });

  testWidgets('vehicle form, editing — light', (tester) async {
    await _captureVehicle(
      tester,
      'fleet_vehicle_2_editing_light',
      vehicle: _vehicle,
    );
  });

  testWidgets('vehicle form, unsaved-changes exit guard — light', (
    tester,
  ) async {
    await _captureVehicle(
      tester,
      'fleet_vehicle_3_unsaved_changes_light',
      vehicle: _vehicle,
      afterPump: (tester) async {
        await tester.enterText(
          find.widgetWithText(TextFormField, 'كود المركبة'),
          'BUS-999',
        );
        await tester.pump();
        await tester.tap(find.byIcon(Icons.close_rounded).first);
        await tester.pumpAndSettle();
      },
    );
  });
}

Future<void> _captureDriver(
  WidgetTester tester,
  String name, {
  required FleetDriver? driver,
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  await _pump(
    tester,
    name,
    child: FleetDriverFormView(
      driver: driver,
      workspace: _workspace,
      onBack: () {},
      onSave: (d, List<PendingFleetDocument> docs) async => null,
    ),
    afterPump: afterPump,
  );
}

Future<void> _captureVehicle(
  WidgetTester tester,
  String name, {
  required FleetVehicle? vehicle,
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  await _pump(
    tester,
    name,
    child: FleetVehicleFormView(
      vehicle: vehicle,
      workspace: _workspace,
      onBack: () {},
      onUploadFile: (_, _, _) async => '',
      onSave: (v, List<PendingFleetDocument> docs) async => null,
    ),
    afterPump: afterPump,
  );
}

Future<void> _pump(
  WidgetTester tester,
  String name, {
  required Widget child,
  double width = 1400,
  double height = 1400,
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _lightThemeWithHostFont(),
      builder: (context, wrapped) => Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(key: key, child: wrapped!),
      ),
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
  await tester.pump();
  if (afterPump != null) await afterPump(tester);

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

ThemeData _lightThemeWithHostFont() {
  final scheme = lightColorSchemeFromPalette();
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    fontFamily: _captureFont,
    scaffoldBackgroundColor: AppLightColors.background,
    canvasColor: AppLightColors.background,
    cardColor: scheme.surface,
    dividerColor: scheme.outline,
    shadowColor: AppLightColors.shadow,
    extensions: [AppSurfaceStyle.dashboardLight(scheme)],
  );
}
