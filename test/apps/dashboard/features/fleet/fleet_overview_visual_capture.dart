/// Visual QA harness for إدارة الأسطول — the Fleet Overview screen — in both
/// themes.
///
/// This screen has never had one: it stacks summary KPIs, a "needs your
/// attention" grid (with an overflow tail), a tab switcher, the drivers table
/// (itself pulled from a sibling module), and two collapsible analytics
/// panels, all in one scrolling page. None of that can be judged from code.
///
/// Not a test of behaviour and deliberately not part of the suite's
/// assertions: run it with `--update-goldens` and look at the PNGs it writes
/// to `_captures/`.
///
///     flutter test test/apps/dashboard/features/fleet/fleet_overview_visual_capture.dart --update-goldens
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_light_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
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

const _captureFont = 'CaptureArabic';

/// Fixed so every expiry computed off it (`FleetExpiry.levelOf`, which reads
/// the real wall clock) lands in the same bucket on every run — a driver seeded
/// "expiring in 12 days" must not silently flip to "expired" a fortnight from
/// now.
final DateTime _now = DateTime(2026, 8, 21);

String _dateOffset(int days) =>
    _now.add(Duration(days: days)).toIso8601String().split('T').first;

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (file.existsSync()) {
      final loader = FontLoader(_captureFont)
        ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      await loader.load();
    }

    // Registers the real MaterialIcons glyphs under the font family every
    // `Icon(Icons.*)` in the module expects, so icons render as themselves
    // instead of tofu boxes in the captures. `flutter test` sets FLUTTER_ROOT
    // for its child process, which is the only portable way to find the SDK's
    // bundled font on any machine this runs on.
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      final iconFont = File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (iconFont.existsSync()) {
        final iconLoader = FontLoader('MaterialIcons')
          ..addFont(
            Future.value(ByteData.sublistView(iconFont.readAsBytesSync())),
          );
        await iconLoader.load();
      }
    }
  });

  setUp(() {
    DashboardSectionStateStore.instance.clear();
    // The driver-readiness, vehicle-status and activity panels default to
    // *collapsed* in the real app (`initiallyExpanded: false`) — force them
    // open so a "full page" capture actually shows the charts instead of
    // three empty headers.
    for (final id in [
      DashboardSectionIds.fleetDriverReadiness,
      DashboardSectionIds.fleetVehicleStatus,
      DashboardSectionIds.fleetActivity,
    ]) {
      DashboardSectionStateStore.instance.setExpanded(id, true);
    }
  });
  tearDown(() => DashboardSectionStateStore.instance.clear());

  testWidgets('the full page, light', (tester) async {
    await _capture(tester, 'fleet_overview_1_full_light', dark: false);
  });

  testWidgets('the full page, dark', (tester) async {
    await _capture(tester, 'fleet_overview_2_full_dark', dark: true);
  });
}

/// Ten drivers and nine vehicles spanning every treatment the screen draws:
/// a healthy assigned pair, a license expiring soon, a license already
/// expired, a suspended driver, a driver missing its license document, a
/// vehicle with no driver assigned, a vehicle in maintenance, a suspended
/// vehicle, a vehicle with an expired insurance document, a vehicle with an
/// inspection expiring soon, one driver/vehicle pair that is assigned but has
/// never completed a trip (idle), one vehicle mid-trip right now, and one
/// archived driver + vehicle for status variety.
FleetWorkspace _buildWorkspace() {
  final drivers = [
    FleetDriver(
      id: 'd1',
      employeeCode: 'EMP-1001',
      fullName: 'أحمد فتحي السيد',
      phone: '01001234501',
      emergencyPhone: '01001234599',
      address: 'القاهرة',
      nationalId: '29001010100011',
      profileImageUrl: '',
      licenseNumber: 'DRV-5001',
      licenseExpiryDate: _dateOffset(400),
      hireDate: _dateOffset(-900),
      notes: '',
      status: FleetDriverStatus.active,
      currentVehicleId: 'v1',
      updatedAt: _now.subtract(const Duration(days: 2)),
      documents: [
        FleetDocument(
          id: 'doc-d1-lic',
          type: FleetDocumentType.driverLicense,
          ownerId: 'd1',
          ownerName: 'أحمد فتحي السيد',
          referenceNumber: 'DL-1001',
          expiryDate: _dateOffset(400),
          status: FleetDocumentStatus.valid,
        ),
        FleetDocument(
          id: 'doc-d1-nid',
          type: FleetDocumentType.nationalIdFront,
          ownerId: 'd1',
          ownerName: 'أحمد فتحي السيد',
          referenceNumber: '29001010100011',
          expiryDate: _dateOffset(1500),
          status: FleetDocumentStatus.valid,
        ),
      ],
      completedTripsCount: 186,
      cancelledTripsCount: 5,
      rating: 4.8,
      ratingCount: 132,
    ),
    FleetDriver(
      id: 'd2',
      employeeCode: 'EMP-1002',
      fullName: 'محمد جمال حلمي',
      phone: '01001234502',
      emergencyPhone: '01001234598',
      address: 'الجيزة',
      nationalId: '29002020200022',
      profileImageUrl: '',
      licenseNumber: 'DRV-5002',
      // Expiring soon: inside the 30-day window.
      licenseExpiryDate: _dateOffset(12),
      hireDate: _dateOffset(-700),
      notes: '',
      status: FleetDriverStatus.active,
      updatedAt: _now.subtract(const Duration(days: 6)),
      documents: [
        FleetDocument(
          id: 'doc-d2-lic',
          type: FleetDocumentType.driverLicense,
          ownerId: 'd2',
          ownerName: 'محمد جمال حلمي',
          referenceNumber: 'DL-1002',
          expiryDate: _dateOffset(12),
          status: FleetDocumentStatus.expiringSoon,
        ),
        FleetDocument(
          id: 'doc-d2-nid',
          type: FleetDocumentType.nationalIdFront,
          ownerId: 'd2',
          ownerName: 'محمد جمال حلمي',
          referenceNumber: '29002020200022',
          expiryDate: _dateOffset(1200),
          status: FleetDocumentStatus.valid,
        ),
      ],
      completedTripsCount: 54,
      cancelledTripsCount: 2,
      rating: 4.5,
      ratingCount: 40,
    ),
    FleetDriver(
      id: 'd3',
      employeeCode: 'EMP-1003',
      fullName: 'كريم عادل يوسف',
      phone: '01001234503',
      emergencyPhone: '01001234597',
      address: 'المنصورة',
      nationalId: '29003030300033',
      profileImageUrl: '',
      licenseNumber: 'DRV-5003',
      // Already expired.
      licenseExpiryDate: _dateOffset(-9),
      hireDate: _dateOffset(-500),
      notes: '',
      status: FleetDriverStatus.active,
      updatedAt: _now.subtract(const Duration(days: 20)),
      documents: [
        FleetDocument(
          id: 'doc-d3-lic',
          type: FleetDocumentType.driverLicense,
          ownerId: 'd3',
          ownerName: 'كريم عادل يوسف',
          referenceNumber: 'DL-1003',
          expiryDate: _dateOffset(-9),
          status: FleetDocumentStatus.expired,
        ),
        FleetDocument(
          id: 'doc-d3-nid',
          type: FleetDocumentType.nationalIdFront,
          ownerId: 'd3',
          ownerName: 'كريم عادل يوسف',
          referenceNumber: '29003030300033',
          expiryDate: _dateOffset(900),
          status: FleetDocumentStatus.valid,
        ),
      ],
      completedTripsCount: 21,
      cancelledTripsCount: 6,
      rating: 3.9,
      ratingCount: 15,
    ),
    FleetDriver(
      id: 'd4',
      employeeCode: 'EMP-1004',
      fullName: 'سامح رضا فوزي',
      phone: '01001234504',
      emergencyPhone: '01001234596',
      address: 'طنطا',
      nationalId: '29004040400044',
      profileImageUrl: '',
      licenseNumber: 'DRV-5004',
      licenseExpiryDate: _dateOffset(200),
      hireDate: _dateOffset(-1100),
      notes: 'موقوف بعد شكوى من عميل بتاريخ 2026-08-01.',
      status: FleetDriverStatus.suspended,
      updatedAt: _now.subtract(const Duration(days: 15)),
      documents: [
        FleetDocument(
          id: 'doc-d4-lic',
          type: FleetDocumentType.driverLicense,
          ownerId: 'd4',
          ownerName: 'سامح رضا فوزي',
          referenceNumber: 'DL-1004',
          expiryDate: _dateOffset(200),
          status: FleetDocumentStatus.valid,
        ),
      ],
      completedTripsCount: 63,
      cancelledTripsCount: 9,
      rating: 4.1,
      ratingCount: 30,
    ),
    FleetDriver(
      id: 'd5',
      employeeCode: 'EMP-1005',
      fullName: 'عمر حسين طه',
      phone: '01001234505',
      emergencyPhone: '01001234595',
      address: 'الإسكندرية',
      nationalId: '29005050500055',
      profileImageUrl: '',
      licenseNumber: 'DRV-5005',
      licenseExpiryDate: _dateOffset(300),
      hireDate: _dateOffset(-60),
      notes: '',
      status: FleetDriverStatus.active,
      updatedAt: _now.subtract(const Duration(days: 1)),
      // Driver-license document was never uploaded.
      documents: [
        FleetDocument(
          id: 'doc-d5-nid',
          type: FleetDocumentType.nationalIdFront,
          ownerId: 'd5',
          ownerName: 'عمر حسين طه',
          referenceNumber: '29005050500055',
          expiryDate: _dateOffset(1000),
          status: FleetDocumentStatus.valid,
        ),
      ],
      completedTripsCount: 8,
      cancelledTripsCount: 1,
      rating: 4.4,
      ratingCount: 6,
    ),
    FleetDriver(
      id: 'd6',
      employeeCode: 'EMP-1006',
      fullName: 'طارق منصور عبد الله',
      phone: '01001234506',
      emergencyPhone: '01001234594',
      address: 'بنها',
      nationalId: '29006060600066',
      profileImageUrl: '',
      licenseNumber: 'DRV-5006',
      licenseExpiryDate: _dateOffset(250),
      hireDate: _dateOffset(-400),
      notes: '',
      status: FleetDriverStatus.active,
      currentVehicleId: 'v7',
      updatedAt: _now.subtract(const Duration(days: 3)),
      documents: [
        FleetDocument(
          id: 'doc-d6-lic',
          type: FleetDocumentType.driverLicense,
          ownerId: 'd6',
          ownerName: 'طارق منصور عبد الله',
          referenceNumber: 'DL-1006',
          expiryDate: _dateOffset(250),
          status: FleetDocumentStatus.valid,
        ),
      ],
      completedTripsCount: 95,
      cancelledTripsCount: 3,
      rating: 4.6,
      ratingCount: 58,
    ),
    FleetDriver(
      id: 'd7',
      employeeCode: 'EMP-1007',
      fullName: 'هشام صلاح الدين',
      phone: '01001234507',
      emergencyPhone: '01001234593',
      address: 'الزقازيق',
      nationalId: '29007070700077',
      profileImageUrl: '',
      licenseNumber: 'DRV-5007',
      licenseExpiryDate: _dateOffset(180),
      hireDate: _dateOffset(-1300),
      notes: '',
      status: FleetDriverStatus.active,
      currentVehicleId: 'v5',
      updatedAt: _now.subtract(const Duration(hours: 6)),
      documents: [
        FleetDocument(
          id: 'doc-d7-lic',
          type: FleetDocumentType.driverLicense,
          ownerId: 'd7',
          ownerName: 'هشام صلاح الدين',
          referenceNumber: 'DL-1007',
          expiryDate: _dateOffset(180),
          status: FleetDocumentStatus.valid,
        ),
      ],
      completedTripsCount: 210,
      cancelledTripsCount: 4,
      rating: 4.9,
      ratingCount: 160,
    ),
    FleetDriver(
      id: 'd8',
      employeeCode: 'EMP-1008',
      fullName: 'وائل عبد الناصر منصور',
      phone: '01001234508',
      emergencyPhone: '01001234592',
      address: 'دمياط',
      nationalId: '29008080800088',
      profileImageUrl: '',
      licenseNumber: 'DRV-5008',
      licenseExpiryDate: _dateOffset(220),
      hireDate: _dateOffset(-10),
      notes: 'انضم حديثاً — لم يبدأ رحلات بعد.',
      status: FleetDriverStatus.active,
      currentVehicleId: 'v8',
      updatedAt: _now.subtract(const Duration(days: 10)),
      documents: [
        FleetDocument(
          id: 'doc-d8-lic',
          type: FleetDocumentType.driverLicense,
          ownerId: 'd8',
          ownerName: 'وائل عبد الناصر منصور',
          referenceNumber: 'DL-1008',
          expiryDate: _dateOffset(220),
          status: FleetDocumentStatus.valid,
        ),
      ],
      completedTripsCount: 0,
      cancelledTripsCount: 0,
      rating: 0,
      ratingCount: 0,
    ),
    FleetDriver(
      id: 'd9',
      employeeCode: 'EMP-1009',
      fullName: 'بلال أشرف نبيل',
      phone: '01001234509',
      emergencyPhone: '01001234591',
      address: 'أسيوط',
      nationalId: '29009090900099',
      profileImageUrl: '',
      licenseNumber: 'DRV-5009',
      licenseExpiryDate: _dateOffset(150),
      hireDate: _dateOffset(-600),
      notes: '',
      status: FleetDriverStatus.active,
      currentVehicleId: 'v6',
      updatedAt: _now.subtract(const Duration(days: 4)),
      documents: [
        FleetDocument(
          id: 'doc-d9-lic',
          type: FleetDocumentType.driverLicense,
          ownerId: 'd9',
          ownerName: 'بلال أشرف نبيل',
          referenceNumber: 'DL-1009',
          expiryDate: _dateOffset(150),
          status: FleetDocumentStatus.valid,
        ),
      ],
      completedTripsCount: 72,
      cancelledTripsCount: 2,
      rating: 4.3,
      ratingCount: 44,
    ),
    FleetDriver(
      id: 'd10',
      employeeCode: 'EMP-1010',
      fullName: 'منير سعيد حلمي',
      phone: '01001234510',
      emergencyPhone: '',
      address: '',
      nationalId: '29001111100010',
      profileImageUrl: '',
      licenseNumber: 'DRV-5010',
      licenseExpiryDate: _dateOffset(-500),
      hireDate: _dateOffset(-2200),
      notes: 'مؤرشف — ترك العمل.',
      status: FleetDriverStatus.archived,
      updatedAt: _now.subtract(const Duration(days: 300)),
      completedTripsCount: 45,
      cancelledTripsCount: 12,
      rating: 4.0,
      ratingCount: 20,
    ),
  ];

  final vehicles = [
    FleetVehicle(
      id: 'v1',
      vehicleCode: 'BUS-101',
      plateNumber: 'ط س و 1234',
      vehicleType: 'hiace',
      brand: 'تويوتا',
      model: 'هايس',
      manufactureYear: 2022,
      color: 'أبيض',
      capacity: 14,
      seatLayoutType: 'hiace_14',
      imageUrl: '',
      notes: '',
      status: FleetVehicleStatus.active,
      currentDriverId: 'd1',
      updatedAt: _now.subtract(const Duration(days: 2)),
      seatConfiguration: SeatConfiguration.generateDefault(14),
      licenseExpiry: _dateOffset(300),
      insuranceExpiry: _dateOffset(200),
      inspectionExpiry: _dateOffset(150),
      completedTripsCount: 186,
      cancelledTripsCount: 5,
      rating: 4.7,
      ratingCount: 120,
    ),
    FleetVehicle(
      id: 'v2',
      vehicleCode: 'BUS-102',
      plateNumber: 'ب د س 2345',
      vehicleType: 'coaster',
      brand: 'هيونداي',
      model: 'كوستر',
      manufactureYear: 2021,
      color: 'أزرق',
      capacity: 28,
      seatLayoutType: 'coaster_28',
      imageUrl: '',
      notes: '',
      status: FleetVehicleStatus.active,
      // No driver assigned.
      updatedAt: _now.subtract(const Duration(days: 5)),
      seatConfiguration: SeatConfiguration.generateDefault(28),
      licenseExpiry: _dateOffset(280),
      insuranceExpiry: _dateOffset(220),
      inspectionExpiry: _dateOffset(120),
      completedTripsCount: 40,
      cancelledTripsCount: 3,
      rating: 4.2,
      ratingCount: 25,
    ),
    FleetVehicle(
      id: 'v3',
      vehicleCode: 'BUS-103',
      plateNumber: 'ج هـ ك 3456',
      vehicleType: 'hiace',
      brand: 'تويوتا',
      model: 'هايس',
      manufactureYear: 2019,
      color: 'رمادي',
      capacity: 14,
      seatLayoutType: 'hiace_14',
      imageUrl: '',
      notes: 'في الصيانة الدورية — تغيير فرامل.',
      status: FleetVehicleStatus.maintenance,
      updatedAt: _now.subtract(const Duration(days: 1)),
      seatConfiguration: SeatConfiguration.generateDefault(14),
      licenseExpiry: _dateOffset(200),
      insuranceExpiry: _dateOffset(150),
      inspectionExpiry: _dateOffset(100),
      completedTripsCount: 15,
      cancelledTripsCount: 1,
      rating: 4.0,
      ratingCount: 10,
    ),
    FleetVehicle(
      id: 'v4',
      vehicleCode: 'BUS-104',
      plateNumber: 'د ر س 4567',
      vehicleType: 'coaster',
      brand: 'ميتسوبيشي',
      model: 'روزا',
      manufactureYear: 2020,
      color: 'أبيض',
      capacity: 22,
      seatLayoutType: 'rosa_22',
      imageUrl: '',
      notes: 'موقوفة بقرار إداري.',
      status: FleetVehicleStatus.suspended,
      updatedAt: _now.subtract(const Duration(days: 25)),
      seatConfiguration: SeatConfiguration.generateDefault(22),
      licenseExpiry: _dateOffset(180),
      insuranceExpiry: _dateOffset(140),
      inspectionExpiry: _dateOffset(90),
      completedTripsCount: 5,
      cancelledTripsCount: 4,
      rating: 3.5,
      ratingCount: 8,
    ),
    FleetVehicle(
      id: 'v5',
      vehicleCode: 'BUS-105',
      plateNumber: 'هـ ص ع 5678',
      vehicleType: 'hiace',
      brand: 'تويوتا',
      model: 'هايس',
      manufactureYear: 2023,
      color: 'فضي',
      capacity: 14,
      seatLayoutType: 'hiace_14',
      imageUrl: '',
      notes: '',
      status: FleetVehicleStatus.active,
      currentDriverId: 'd7',
      updatedAt: _now.subtract(const Duration(hours: 6)),
      seatConfiguration: SeatConfiguration.generateDefault(14),
      licenseExpiry: _dateOffset(300),
      // Already expired.
      insuranceExpiry: _dateOffset(-14),
      inspectionExpiry: _dateOffset(100),
      completedTripsCount: 210,
      cancelledTripsCount: 6,
      rating: 4.7,
      ratingCount: 150,
    ),
    FleetVehicle(
      id: 'v6',
      vehicleCode: 'BUS-106',
      plateNumber: 'و ع ل 6789',
      vehicleType: 'coaster',
      brand: 'هيونداي',
      model: 'كوستر',
      manufactureYear: 2022,
      color: 'أبيض',
      capacity: 28,
      seatLayoutType: 'coaster_28',
      imageUrl: '',
      notes: '',
      status: FleetVehicleStatus.active,
      currentDriverId: 'd9',
      updatedAt: _now.subtract(const Duration(days: 4)),
      seatConfiguration: SeatConfiguration.generateDefault(28),
      licenseExpiry: _dateOffset(300),
      insuranceExpiry: _dateOffset(180),
      // Expiring soon.
      inspectionExpiry: _dateOffset(18),
      completedTripsCount: 72,
      cancelledTripsCount: 2,
      rating: 4.4,
      ratingCount: 48,
    ),
    FleetVehicle(
      id: 'v7',
      vehicleCode: 'BUS-107',
      plateNumber: 'ز ف م 7890',
      vehicleType: 'hiace',
      brand: 'تويوتا',
      model: 'هايس',
      manufactureYear: 2022,
      color: 'أسود',
      capacity: 14,
      seatLayoutType: 'hiace_14',
      imageUrl: '',
      notes: '',
      status: FleetVehicleStatus.active,
      currentDriverId: 'd6',
      updatedAt: _now.subtract(const Duration(days: 3)),
      seatConfiguration: SeatConfiguration.generateDefault(14),
      licenseExpiry: _dateOffset(260),
      insuranceExpiry: _dateOffset(210),
      inspectionExpiry: _dateOffset(160),
      completedTripsCount: 95,
      cancelledTripsCount: 3,
      rating: 4.6,
      ratingCount: 58,
    ),
    FleetVehicle(
      id: 'v8',
      vehicleCode: 'BUS-108',
      plateNumber: 'ح ق ن 8901',
      vehicleType: 'hiace',
      brand: 'تويوتا',
      model: 'هايس',
      manufactureYear: 2023,
      color: 'أبيض',
      capacity: 14,
      seatLayoutType: 'hiace_14',
      imageUrl: '',
      notes: 'مركبة جديدة — لم تبدأ رحلات بعد.',
      status: FleetVehicleStatus.active,
      currentDriverId: 'd8',
      updatedAt: _now.subtract(const Duration(days: 10)),
      seatConfiguration: SeatConfiguration.generateDefault(14),
      licenseExpiry: _dateOffset(340),
      insuranceExpiry: _dateOffset(340),
      inspectionExpiry: _dateOffset(340),
      completedTripsCount: 0,
      cancelledTripsCount: 0,
      rating: 0,
      ratingCount: 0,
    ),
    FleetVehicle(
      id: 'v9',
      vehicleCode: 'BUS-109',
      plateNumber: 'ط ك هـ 9012',
      vehicleType: 'coaster',
      brand: 'ميتسوبيشي',
      model: 'روزا',
      manufactureYear: 2015,
      color: 'رمادي',
      capacity: 22,
      seatLayoutType: 'rosa_22',
      imageUrl: '',
      notes: 'مؤرشفة — خارج الخدمة نهائياً.',
      status: FleetVehicleStatus.archived,
      updatedAt: _now.subtract(const Duration(days: 400)),
      seatConfiguration: SeatConfiguration.generateDefault(22),
      licenseExpiry: _dateOffset(-800),
      insuranceExpiry: _dateOffset(-800),
      inspectionExpiry: _dateOffset(-800),
      completedTripsCount: 30,
      cancelledTripsCount: 7,
      rating: 3.8,
      ratingCount: 12,
    ),
  ];

  final assignments = [
    const FleetAssignment(
      id: 'a1',
      driverId: 'd1',
      vehicleId: 'v1',
      assignedAt: '2026-04-24',
      status: FleetAssignmentStatus.active,
    ),
    const FleetAssignment(
      id: 'a2',
      driverId: 'd6',
      vehicleId: 'v7',
      assignedAt: '2026-06-03',
      status: FleetAssignmentStatus.active,
    ),
    const FleetAssignment(
      id: 'a3',
      driverId: 'd7',
      vehicleId: 'v5',
      assignedAt: '2026-02-03',
      status: FleetAssignmentStatus.active,
    ),
    const FleetAssignment(
      id: 'a4',
      driverId: 'd9',
      vehicleId: 'v6',
      assignedAt: '2026-07-12',
      status: FleetAssignmentStatus.active,
    ),
    const FleetAssignment(
      id: 'a5',
      driverId: 'd8',
      vehicleId: 'v8',
      assignedAt: '2026-08-11',
      status: FleetAssignmentStatus.active,
    ),
  ];

  final documents = [
    FleetDocument(
      id: 'doc-v5-insurance',
      type: FleetDocumentType.insurance,
      ownerId: 'v5',
      ownerName: 'BUS-105',
      referenceNumber: 'INS-5105',
      expiryDate: _dateOffset(-14),
      status: FleetDocumentStatus.expired,
    ),
    FleetDocument(
      id: 'doc-v6-inspection',
      type: FleetDocumentType.inspection,
      ownerId: 'v6',
      ownerName: 'BUS-106',
      referenceNumber: 'INSP-6106',
      expiryDate: _dateOffset(18),
      status: FleetDocumentStatus.expiringSoon,
    ),
    FleetDocument(
      id: 'doc-d2-license',
      type: FleetDocumentType.driverLicense,
      ownerId: 'd2',
      ownerName: 'محمد جمال حلمي',
      referenceNumber: 'DL-1002',
      expiryDate: _dateOffset(12),
      status: FleetDocumentStatus.expiringSoon,
    ),
    FleetDocument(
      id: 'doc-d3-license',
      type: FleetDocumentType.driverLicense,
      ownerId: 'd3',
      ownerName: 'كريم عادل يوسف',
      referenceNumber: 'DL-1003',
      expiryDate: _dateOffset(-9),
      status: FleetDocumentStatus.expired,
    ),
  ];

  final duties = [
    FleetVehicleDuty(
      vehicleId: 'v1',
      tripId: 't-1001',
      tripCode: 'TRP-1001',
      status: 'in_progress',
      tripDate: _now,
      departureTime: '07:00',
      driverId: 'd1',
      routeName: 'القاهرة → الإسكندرية',
    ),
    FleetVehicleDuty(
      vehicleId: 'v7',
      tripId: 't-1002',
      tripCode: 'TRP-1002',
      status: 'scheduled',
      tripDate: _now.add(const Duration(days: 2)),
      departureTime: '06:30',
      driverId: 'd6',
      routeName: 'طنطا → المنصورة',
    ),
  ];

  return FleetWorkspace(
    drivers: drivers,
    vehicles: vehicles,
    assignments: assignments,
    documents: documents,
    duties: duties,
  );
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required bool dark,
  double width = 1440,
  // The page's own SingleChildScrollView sizes itself to its content under
  // Scaffold's loose constraints (it does not stretch to fill available
  // height), so the golden is exactly this tall regardless of how much
  // content there is — this value was tuned by measuring the drivers-tab
  // page's actual rendered height (~2097 logical px with every panel forced
  // open) and rounding up, so the capture is tight with a small safety
  // margin rather than mostly blank canvas.
  double height = 2180,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final workspace = _buildWorkspace();

  dashboardDi
    ..registerFactory<FleetDriversCubit>(
      () => _StaticDriversCubit(FleetDriversLoaded(drivers: workspace.drivers)),
    )
    ..registerFactory<FleetVehiclesCubit>(
      () => _StaticVehiclesCubit(
        FleetVehiclesLoaded(vehicles: workspace.vehicles),
      ),
    )
    ..registerFactory<FleetDocumentsCubit>(
      () => _StaticDocumentsCubit(
        FleetDocumentsLoaded(documents: workspace.documents),
      ),
    );
  addTearDown(dashboardDi.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _themeWithHostFont(dark: dark),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: BlocProvider<FleetOverviewCubit>.value(
              value: _StaticOverviewCubit(FleetOverviewLoaded(workspace)),
              child: const FleetOverviewScreen(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

/// See the note in the customers/bookings harnesses: the real themes build
/// their text theme through google_fonts, which the test binding's blocked
/// network turns into a post-test throw. The palette is the real one; only
/// the glyphs differ.
ThemeData _themeWithHostFont({required bool dark}) {
  final scheme = dark
      ? darkColorSchemeFromPalette()
      : lightColorSchemeFromPalette();
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    fontFamily: _captureFont,
    scaffoldBackgroundColor: dark
        ? AppDarkColors.background
        : AppLightColors.background,
    canvasColor: dark ? AppDarkColors.background : AppLightColors.background,
    cardColor: scheme.surface,
    dividerColor: scheme.outline,
    shadowColor: dark ? AppDarkColors.shadow : AppLightColors.shadow,
    extensions: [
      dark ? AppSurfaceStyle.flat(scheme) : AppSurfaceStyle.dashboardLight(scheme),
    ],
  );
}

class _StaticOverviewCubit extends Cubit<FleetOverviewState>
    implements FleetOverviewCubit {
  _StaticOverviewCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StaticDriversCubit extends Cubit<FleetDriversState>
    implements FleetDriversCubit {
  _StaticDriversCubit(super.initialState);

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StaticVehiclesCubit extends Cubit<FleetVehiclesState>
    implements FleetVehiclesCubit {
  _StaticVehiclesCubit(super.initialState);

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StaticDocumentsCubit extends Cubit<FleetDocumentsState>
    implements FleetDocumentsCubit {
  _StaticDocumentsCubit(super.initialState);

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
