/// Visual QA harness for the Dashboard Home landing screen — the composition
/// root that pulls nine other features' data into one page: the greeting
/// banner, four KPIs, the "يحتاج إلى إجراء" attention panel, today's
/// departures beside the newest bookings, the revenue line and top routes,
/// then fleet/team counts beside the activity feed. None of that layout, nor
/// the LIGHT-mode card treatment ([AppSurfaceStyle.dashboardLight]) it is
/// meant to showcase, can be judged from code.
///
/// Not a test of behaviour and deliberately not part of the suite's assertions:
/// run it with `--update-goldens` and look at the PNGs it writes to
/// `_captures/`.
///
///     flutter test test/apps/dashboard/features/dashboard_home/dashboard_home_visual_capture.dart --update-goldens
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
import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/entities/captain_request.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/domain/entities/dashboard_home_summary.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/cubit/dashboard_home_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/cubit/dashboard_home_state.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/screens/dashboard_home_screen.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart'
    show RevenueMetrics;
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/domain/entities/operational_alert.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_state.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/domain/entities/trip_review_entry.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/entities/complaint.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';

const _captureFont = 'CaptureArabic';

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(_captureFont)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  });

  setUp(DashboardSectionStateStore.instance.clear);
  tearDown(DashboardSectionStateStore.instance.clear);

  testWidgets('the full page, light', (tester) async {
    await _capture(
      tester,
      'dashboard_home_1_full_light',
      dark: false,
      width: 1440,
      height: 3150,
    );
  });

  testWidgets('the full page, dark', (tester) async {
    await _capture(
      tester,
      'dashboard_home_2_full_dark',
      dark: true,
      width: 1440,
      height: 3150,
    );
  });

  testWidgets('narrow — bands stack below the split breakpoint', (
    tester,
  ) async {
    await _capture(
      tester,
      'dashboard_home_3_narrow_light',
      dark: false,
      width: 900,
      height: 4300,
    );
  });
}

// ─────────────────────────────────────────────────────────────────────────
// Fixtures — realistic, internally-consistent office data. Driver names are
// shared between the trip list and the fleet roster on purpose, the way one
// real office's data would agree with itself.
// ─────────────────────────────────────────────────────────────────────────

final DateTime _now = DateTime.now();

DateTime _onDay(int dayOffset, {required int hour, int minute = 0}) =>
    DateTime(_now.year, _now.month, _now.day + dayOffset, hour, minute);

String _two(int n) => n.toString().padLeft(2, '0');
String _dateStr(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
String _timeStr(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

const _office = OfficeContext(
  officeId: 'office-fast-transport',
  officeName: 'مكتب النقل السريع',
  officeSlug: 'fast-transport',
  role: DashboardRole.admin,
  username: 'admin',
  fullName: 'محمود يوسف',
  listingStatus: 'listed',
);

List<TripSeat> _seats(String tripId, {required int capacity, required int booked}) {
  return [
    for (var i = 0; i < capacity; i++)
      TripSeat(
        id: '$tripId-seat-$i',
        label: '${i + 1}',
        row: i ~/ 3 + 1,
        column: i % 3 + 1,
        state: i < booked ? TripSeatState.paid : TripSeatState.available,
      ),
  ];
}

OperationTrip _trip({
  required String id,
  required String route,
  required String driver,
  required String vehicle,
  required int dayOffset,
  required int hour,
  int minute = 0,
  required OperationTripStatus status,
  required int capacity,
  required int booked,
  double ticketPrice = 85,
}) {
  final at = _onDay(dayOffset, hour: hour, minute: minute);
  return OperationTrip(
    id: id,
    routeId: '$id-route',
    route: route,
    routePoints: const [],
    driverId: driver.isEmpty ? '' : '$id-driver',
    driver: driver,
    vehicleId: vehicle.isEmpty ? '' : '$id-vehicle',
    vehicle: vehicle,
    vehicleType: 'hiace',
    date: _dateStr(at),
    departure: _timeStr(at),
    arrival: '',
    status: status,
    capacity: capacity,
    ticketPrice: ticketPrice,
    seats: _seats(id, capacity: capacity, booked: booked),
    passengers: const [],
    events: const [],
    notes: const [],
  );
}

/// Today's departures (varying status/occupancy, one with no captain) plus a
/// trip that fell into the stale-booking trap and a handful genuinely ahead.
List<OperationTrip> _trips() => [
  // Today.
  _trip(
    id: 't1',
    route: 'القاهرة → الإسكندرية',
    driver: 'كريم عبد الله',
    vehicle: 'هايس (KLM 1234)',
    dayOffset: 0,
    hour: 7,
    status: OperationTripStatus.openForBooking,
    capacity: 14,
    booked: 10,
  ),
  _trip(
    id: 't2',
    route: 'الإسكندرية → القاهرة',
    driver: 'محمد صلاح الدين',
    vehicle: 'كوستر (ABC 5678)',
    dayOffset: 0,
    hour: 8,
    minute: 30,
    status: OperationTripStatus.boarding,
    capacity: 24,
    booked: 22,
  ),
  _trip(
    id: 't3',
    route: 'القاهرة → المنصورة',
    driver: 'أحمد الجندي',
    vehicle: 'هايس (XYZ 9012)',
    dayOffset: 0,
    hour: 10,
    status: OperationTripStatus.inProgress,
    capacity: 14,
    booked: 14,
  ),
  _trip(
    id: 't4',
    route: 'طنطا → الإسكندرية',
    driver: '', // no captain assigned — feeds tripsWithoutCaptain.
    vehicle: '',
    dayOffset: 0,
    hour: 13,
    status: OperationTripStatus.openForBooking,
    capacity: 14,
    booked: 4,
  ),
  _trip(
    id: 't5',
    route: 'القاهرة → الإسكندرية',
    driver: 'سامي عزت',
    vehicle: 'هايس (DEF 3456)',
    dayOffset: 0,
    hour: 18,
    status: OperationTripStatus.scheduled,
    capacity: 14,
    booked: 6,
  ),
  _trip(
    id: 't6',
    route: 'المنصورة → القاهرة',
    driver: 'طارق فؤاد',
    vehicle: 'هايس (KLM 1234)',
    dayOffset: 0,
    hour: 20,
    status: OperationTripStatus.completed,
    capacity: 14,
    booked: 14,
  ),
  _trip(
    id: 't7',
    route: 'القاهرة → الزقازيق',
    driver: 'خالد نبيل',
    vehicle: 'هايس (XYZ 9012)',
    dayOffset: 0,
    hour: 9,
    status: OperationTripStatus.cancelled,
    capacity: 14,
    booked: 0,
  ),
  // Stale: departure day already passed, still open for booking.
  _trip(
    id: 't8',
    route: 'بنها → القاهرة',
    driver: 'نادر فتحي',
    vehicle: 'هايس (DEF 3456)',
    dayOffset: -1,
    hour: 7,
    status: OperationTripStatus.openForBooking,
    capacity: 14,
    booked: 3,
  ),
  // Upcoming.
  _trip(
    id: 't9',
    route: 'القاهرة → الإسكندرية',
    driver: 'كريم عبد الله',
    vehicle: 'هايس (KLM 1234)',
    dayOffset: 1,
    hour: 7,
    status: OperationTripStatus.openForBooking,
    capacity: 14,
    booked: 5,
  ),
  _trip(
    id: 't10',
    route: 'الإسكندرية → القاهرة',
    driver: 'محمد صلاح الدين',
    vehicle: 'كوستر (ABC 5678)',
    dayOffset: 1,
    hour: 15,
    status: OperationTripStatus.scheduled,
    capacity: 24,
    booked: 2,
  ),
  _trip(
    id: 't11',
    route: 'طنطا → المنصورة',
    driver: 'أحمد الجندي',
    vehicle: 'هايس (XYZ 9012)',
    dayOffset: 2,
    hour: 9,
    status: OperationTripStatus.scheduled,
    capacity: 14,
    booked: 0,
  ),
  _trip(
    id: 't12',
    route: 'القاهرة → السويس',
    driver: 'سامي عزت',
    vehicle: 'هايس (DEF 3456)',
    dayOffset: 3,
    hour: 6,
    minute: 30,
    status: OperationTripStatus.openForBooking,
    capacity: 14,
    booked: 9,
  ),
];

int _bkCounter = 0;

OperationBooking _booking({
  required String passenger,
  required String route,
  required double amount,
  required int daysAgo,
  int hour = 9,
  int minute = 0,
  BookingStatus status = BookingStatus.confirmed,
  PaymentStatus paymentStatus = PaymentStatus.approved,
  String seat = 'A1',
}) {
  _bkCounter++;
  final created = _onDay(-daysAgo, hour: hour, minute: minute);
  final hasReceipt =
      paymentStatus == PaymentStatus.approved ||
      paymentStatus == PaymentStatus.submitted;
  return OperationBooking(
    id: 'bk-$_bkCounter',
    bookingNumber: 'BK-${100000 + _bkCounter}',
    clientId: 'client-$_bkCounter',
    passengerName: passenger,
    phone: '0100000${_bkCounter.toString().padLeft(4, '0')}',
    route: route,
    tripTime: _timeStr(created),
    date: _dateStr(created),
    seat: seat,
    paymentMethod: BookingPaymentMethod.instaPay,
    status: status,
    paymentStatus: paymentStatus,
    paymentAmount: amount,
    packageName: '',
    createdAt: created,
    tripDetails: BookingTripDetails.empty,
    notes: const [],
    timeline: const [],
    receiptUrl: hasReceipt ? 'https://example.test/receipt.png' : null,
  );
}

/// 20 bookings across the last 7 days, so `bookingRevenueSeries` traces a real
/// line (235 → 280 → 320 → 500 → 180 → 535 → 235, oldest first) instead of a
/// flat or empty one. Three `submitted` receipts feed the payments-review
/// queue; one `cancelled`/`refunded` row and a plain `pending` one round out
/// the status mix.
List<OperationBooking> _bookings() => [
  _booking(
    passenger: 'منى عبد الرحمن',
    route: 'القاهرة → الإسكندرية',
    amount: 85,
    daysAgo: 6,
  ),
  _booking(
    passenger: 'كريم الشاذلي',
    route: 'طنطا → الإسكندرية',
    amount: 150,
    daysAgo: 6,
    hour: 14,
  ),
  _booking(
    passenger: 'سارة مجدي',
    route: 'الإسكندرية → القاهرة',
    amount: 280,
    daysAgo: 5,
  ),
  _booking(
    passenger: 'عبد الرحمن الشناوي',
    route: 'القاهرة → المنصورة',
    amount: 85,
    daysAgo: 4,
  ),
  _booking(
    passenger: 'نورهان فتحي',
    route: 'المنصورة → القاهرة',
    amount: 85,
    daysAgo: 4,
    hour: 12,
  ),
  _booking(
    passenger: 'أيمن الجندي',
    route: 'القاهرة → الإسكندرية',
    amount: 150,
    daysAgo: 4,
    hour: 16,
  ),
  _booking(
    passenger: 'هبة سليمان',
    route: 'الإسكندرية → القاهرة',
    amount: 500,
    daysAgo: 3,
    status: BookingStatus.boarded,
  ),
  _booking(
    passenger: 'رامي عز الدين',
    route: 'القاهرة → الزقازيق',
    amount: 85,
    daysAgo: 3,
    hour: 15,
    paymentStatus: PaymentStatus.submitted,
  ),
  _booking(
    passenger: 'ياسمين محمود',
    route: 'طنطا → الإسكندرية',
    amount: 85,
    daysAgo: 2,
  ),
  _booking(
    passenger: 'عمر خالد',
    route: 'القاهرة → الإسكندرية',
    amount: 95,
    daysAgo: 2,
    hour: 11,
  ),
  _booking(
    passenger: 'دينا أشرف',
    route: 'بنها → القاهرة',
    amount: 85,
    daysAgo: 2,
    hour: 17,
    paymentStatus: PaymentStatus.submitted,
  ),
  _booking(
    passenger: 'محمود يوسف',
    route: 'القاهرة → الإسكندرية',
    amount: 85,
    daysAgo: 1,
  ),
  _booking(
    passenger: 'سارة عبد الرحمن',
    route: 'المنصورة → القاهرة',
    amount: 85,
    daysAgo: 1,
    hour: 10,
  ),
  _booking(
    passenger: 'أحمد الشرقاوي',
    route: 'الإسكندرية → القاهرة',
    amount: 85,
    daysAgo: 1,
    hour: 13,
  ),
  _booking(
    passenger: 'ندى مصطفى',
    route: 'طنطا → الإسكندرية',
    amount: 280,
    daysAgo: 1,
    hour: 16,
    status: BookingStatus.completed,
  ),
  _booking(
    passenger: 'وليد سمير',
    route: 'القاهرة → المنصورة',
    amount: 95,
    daysAgo: 1,
    hour: 18,
    paymentStatus: PaymentStatus.submitted,
  ),
  _booking(
    passenger: 'مريم عادل',
    route: 'القاهرة → الإسكندرية',
    amount: 150,
    daysAgo: 0,
    hour: 6,
  ),
  _booking(
    passenger: 'يوسف كامل',
    route: 'الإسكندرية → القاهرة',
    amount: 85,
    daysAgo: 0,
    hour: 7,
  ),
  _booking(
    passenger: 'هدى إبراهيم',
    route: 'القاهرة → الزقازيق',
    amount: 280,
    daysAgo: 0,
    hour: 8,
    status: BookingStatus.reserved,
    paymentStatus: PaymentStatus.pending,
  ),
  _booking(
    passenger: 'أحمد سامي',
    route: 'طنطا → الإسكندرية',
    amount: 65,
    daysAgo: 0,
    hour: 9,
    status: BookingStatus.cancelled,
    paymentStatus: PaymentStatus.refunded,
  ),
];

const _revenue = RevenueMetrics(
  todayRevenue: 235,
  weeklyRevenue: 2285,
  monthlyRevenue: 15400,
  activeSubscriptions: 47,
  totalBookingsRevenue: 182600,
  totalSubscriptionsRevenue: 64300,
);

FleetWorkspace _fleet() {
  const drivers = [
    FleetDriver(
      id: 'd1',
      employeeCode: 'DRV-001',
      fullName: 'كريم عبد الله',
      phone: '01001112223',
      emergencyPhone: '01001112224',
      address: 'مدينة نصر، القاهرة',
      nationalId: '29001011234567',
      profileImageUrl: '',
      licenseNumber: 'L-4521',
      licenseExpiryDate: '2027-05-01',
      hireDate: '2022-01-10',
      notes: '',
      status: FleetDriverStatus.active,
      rating: 4.7,
      ratingCount: 32,
    ),
    FleetDriver(
      id: 'd2',
      employeeCode: 'DRV-002',
      fullName: 'محمد صلاح الدين',
      phone: '01002223334',
      emergencyPhone: '01002223335',
      address: 'العجمي، الإسكندرية',
      nationalId: '28905022345678',
      profileImageUrl: '',
      licenseNumber: 'L-7743',
      licenseExpiryDate: '2026-11-15',
      hireDate: '2021-06-01',
      notes: '',
      status: FleetDriverStatus.active,
      rating: 4.5,
      ratingCount: 21,
    ),
    FleetDriver(
      id: 'd3',
      employeeCode: 'DRV-003',
      fullName: 'أحمد الجندي',
      phone: '01003334445',
      emergencyPhone: '01003334446',
      address: 'شبرا الخيمة، القليوبية',
      nationalId: '29102033456789',
      profileImageUrl: '',
      licenseNumber: 'L-1290',
      licenseExpiryDate: '2027-02-20',
      hireDate: '2023-03-15',
      notes: '',
      status: FleetDriverStatus.active,
      rating: 4.9,
      ratingCount: 18,
    ),
    FleetDriver(
      id: 'd4',
      employeeCode: 'DRV-004',
      fullName: 'سامي عزت',
      phone: '01004445556',
      emergencyPhone: '01004445557',
      address: 'طنطا، الغربية',
      nationalId: '28808044567890',
      profileImageUrl: '',
      licenseNumber: 'L-8834',
      licenseExpiryDate: '2026-09-10',
      hireDate: '2020-09-01',
      notes: '',
      status: FleetDriverStatus.active,
      rating: 4.2,
      ratingCount: 40,
    ),
    FleetDriver(
      id: 'd5',
      employeeCode: 'DRV-005',
      fullName: 'طارق فؤاد',
      phone: '01005556667',
      emergencyPhone: '01005556668',
      address: 'المنصورة، الدقهلية',
      nationalId: '28703055678901',
      profileImageUrl: '',
      licenseNumber: 'L-2210',
      licenseExpiryDate: '2026-08-30',
      hireDate: '2019-04-20',
      notes: 'موقوف مؤقتاً لمراجعة إدارية',
      status: FleetDriverStatus.suspended,
      rating: 3.8,
      ratingCount: 15,
    ),
    FleetDriver(
      id: 'd6',
      employeeCode: 'DRV-006',
      fullName: 'نادر فتحي',
      phone: '01006667778',
      emergencyPhone: '01006667779',
      address: 'بنها، القليوبية',
      nationalId: '29004066789012',
      profileImageUrl: '',
      licenseNumber: 'L-5567',
      licenseExpiryDate: '2027-01-05',
      hireDate: '2022-07-11',
      notes: '',
      status: FleetDriverStatus.active,
      rating: 4.4,
      ratingCount: 9,
    ),
    FleetDriver(
      id: 'd7',
      employeeCode: 'DRV-007',
      fullName: 'خالد نبيل',
      phone: '01007778889',
      emergencyPhone: '01007778880',
      address: 'الزقازيق، الشرقية',
      nationalId: '28609077890123',
      profileImageUrl: '',
      licenseNumber: 'L-9981',
      licenseExpiryDate: '2026-12-01',
      hireDate: '2021-02-14',
      notes: '',
      status: FleetDriverStatus.active,
      rating: 4.0,
      ratingCount: 11,
    ),
  ];

  const vehicles = [
    FleetVehicle(
      id: 'v1',
      vehicleCode: 'هايس (KLM 1234)',
      plateNumber: 'ق ط م 1234',
      vehicleType: 'hiace',
      brand: 'Toyota',
      model: 'Hiace',
      manufactureYear: 2021,
      color: 'أبيض',
      capacity: 14,
      seatLayoutType: 'hiace_14',
      imageUrl: '',
      notes: '',
      status: FleetVehicleStatus.active,
      seatConfiguration: SeatConfiguration(rows: 0, columns: 0, seats: []),
      licenseExpiry: '2027-03-01',
      insuranceExpiry: '2026-09-05',
      inspectionExpiry: '2027-01-01',
    ),
    FleetVehicle(
      id: 'v2',
      vehicleCode: 'كوستر (ABC 5678)',
      plateNumber: 'أ ب ج 5678',
      vehicleType: 'coaster',
      brand: 'Toyota',
      model: 'Coaster',
      manufactureYear: 2019,
      color: 'أزرق',
      capacity: 24,
      seatLayoutType: 'coaster_24',
      imageUrl: '',
      notes: '',
      status: FleetVehicleStatus.active,
      seatConfiguration: SeatConfiguration(rows: 0, columns: 0, seats: []),
      licenseExpiry: '2026-12-20',
      insuranceExpiry: '2027-02-14',
      inspectionExpiry: '2026-10-10',
    ),
    FleetVehicle(
      id: 'v3',
      vehicleCode: 'هايس (XYZ 9012)',
      plateNumber: 'س ص ع 9012',
      vehicleType: 'hiace',
      brand: 'Toyota',
      model: 'Hiace',
      manufactureYear: 2020,
      color: 'فضي',
      capacity: 14,
      seatLayoutType: 'hiace_14',
      imageUrl: '',
      notes: '',
      status: FleetVehicleStatus.active,
      seatConfiguration: SeatConfiguration(rows: 0, columns: 0, seats: []),
      licenseExpiry: '2027-06-01',
      insuranceExpiry: '2027-04-11',
      inspectionExpiry: '2026-11-19',
    ),
    FleetVehicle(
      id: 'v4',
      vehicleCode: 'هايس (DEF 3456)',
      plateNumber: 'د هـ ز 3456',
      vehicleType: 'hiace',
      brand: 'Hyundai',
      model: 'H350',
      manufactureYear: 2018,
      color: 'رمادي',
      capacity: 14,
      seatLayoutType: 'hiace_14',
      imageUrl: '',
      notes: 'في الصيانة الدورية',
      status: FleetVehicleStatus.maintenance,
      seatConfiguration: SeatConfiguration(rows: 0, columns: 0, seats: []),
      licenseExpiry: '2026-07-25',
      insuranceExpiry: '2026-08-30',
      inspectionExpiry: '2026-09-15',
    ),
  ];

  const assignments = [
    FleetAssignment(
      id: 'a1',
      driverId: 'd1',
      vehicleId: 'v1',
      assignedAt: '2024-01-10',
      status: FleetAssignmentStatus.active,
    ),
    FleetAssignment(
      id: 'a2',
      driverId: 'd2',
      vehicleId: 'v2',
      assignedAt: '2023-08-01',
      status: FleetAssignmentStatus.active,
    ),
    FleetAssignment(
      id: 'a3',
      driverId: 'd3',
      vehicleId: 'v3',
      assignedAt: '2024-03-15',
      status: FleetAssignmentStatus.active,
    ),
    FleetAssignment(
      id: 'a4',
      driverId: 'd5',
      vehicleId: 'v4',
      assignedAt: '2022-05-01',
      status: FleetAssignmentStatus.ended,
    ),
  ];

  const documents = [
    FleetDocument(
      id: 'doc1',
      type: FleetDocumentType.driverLicense,
      ownerId: 'd5',
      ownerName: 'طارق فؤاد',
      referenceNumber: 'L-2210',
      expiryDate: '2026-06-01',
      status: FleetDocumentStatus.expired,
    ),
    FleetDocument(
      id: 'doc2',
      type: FleetDocumentType.insurance,
      ownerId: 'v1',
      ownerName: 'هايس (KLM 1234)',
      referenceNumber: 'INS-4471',
      expiryDate: '2026-08-30',
      status: FleetDocumentStatus.expiringSoon,
    ),
    FleetDocument(
      id: 'doc3',
      type: FleetDocumentType.driverLicense,
      ownerId: 'd1',
      ownerName: 'كريم عبد الله',
      referenceNumber: 'L-4521',
      expiryDate: '2027-05-01',
      status: FleetDocumentStatus.valid,
    ),
    FleetDocument(
      id: 'doc4',
      type: FleetDocumentType.inspection,
      ownerId: 'v2',
      ownerName: 'كوستر (ABC 5678)',
      referenceNumber: 'INSP-9981',
      expiryDate: '2026-10-10',
      status: FleetDocumentStatus.valid,
    ),
    FleetDocument(
      id: 'doc5',
      type: FleetDocumentType.nationalIdFront,
      ownerId: 'd2',
      ownerName: 'محمد صلاح الدين',
      referenceNumber: '28905022345678',
      expiryDate: '',
      status: FleetDocumentStatus.valid,
    ),
  ];

  return const FleetWorkspace(
    drivers: drivers,
    vehicles: vehicles,
    assignments: assignments,
    documents: documents,
  );
}

List<CaptainRequest> _captainRequests() => [
  CaptainRequest(
    id: 'cr1',
    fullName: 'زياد سامي محمد',
    phone: '01011112222',
    status: CaptainRequestStatus.pending,
    createdAt: _now.subtract(const Duration(hours: 6)),
  ),
  CaptainRequest(
    id: 'cr2',
    fullName: 'ياسر حسني',
    phone: '01022223333',
    status: CaptainRequestStatus.pending,
    createdAt: _now.subtract(const Duration(days: 1, hours: 3)),
  ),
  CaptainRequest(
    id: 'cr3',
    fullName: 'إسلام عبد الحميد',
    phone: '01033334444',
    status: CaptainRequestStatus.approved,
    createdAt: _now.subtract(const Duration(days: 9)),
    reviewedAt: _now.subtract(const Duration(days: 7)),
    driverId: 'd8',
  ),
];

List<TripReviewEntry> _reviews() => [
  TripReviewEntry(
    id: 'rv1',
    bookingId: 'bk-r1',
    bookingNumber: 'BK-100201',
    clientName: 'منى عبد الرحمن',
    driverName: 'كريم عبد الله',
    vehicleName: 'هايس (KLM 1234)',
    routeLabel: 'القاهرة → الإسكندرية',
    driverRating: 5,
    vehicleRating: 5,
    routeRating: 5,
    comment: 'رحلة ممتازة والتزام تام بالمواعيد.',
    createdAt: _now.subtract(const Duration(hours: 5)),
  ),
  TripReviewEntry(
    id: 'rv2',
    bookingId: 'bk-r2',
    bookingNumber: 'BK-100205',
    clientName: 'سارة مجدي',
    driverName: 'محمد صلاح الدين',
    vehicleName: 'كوستر (ABC 5678)',
    routeLabel: 'الإسكندرية → القاهرة',
    driverRating: 4,
    vehicleRating: 5,
    routeRating: 4,
    comment: 'خدمة جيدة بشكل عام.',
    createdAt: _now.subtract(const Duration(days: 1, hours: 2)),
  ),
  TripReviewEntry(
    id: 'rv3',
    bookingId: 'bk-r3',
    bookingNumber: 'BK-100210',
    clientName: 'أيمن الجندي',
    driverName: 'أحمد الجندي',
    vehicleName: 'هايس (XYZ 9012)',
    routeLabel: 'القاهرة → المنصورة',
    driverRating: 5,
    vehicleRating: 4,
    routeRating: 5,
    comment: '',
    createdAt: _now.subtract(const Duration(days: 2)),
  ),
  TripReviewEntry(
    id: 'rv4',
    bookingId: 'bk-r4',
    bookingNumber: 'BK-100214',
    clientName: 'ندى مصطفى',
    driverName: 'سامي عزت',
    vehicleName: 'هايس (DEF 3456)',
    routeLabel: 'القاهرة → الإسكندرية',
    driverRating: 2,
    vehicleRating: 3,
    routeRating: 4,
    comment: 'السائق تأخر كثيراً عن الموعد ولم يعتذر.',
    createdAt: _now.subtract(const Duration(days: 3, hours: 4)),
  ),
  TripReviewEntry(
    id: 'rv5',
    bookingId: 'bk-r5',
    bookingNumber: 'BK-100218',
    clientName: 'وليد سمير',
    driverName: 'طارق فؤاد',
    vehicleName: 'هايس (KLM 1234)',
    routeLabel: 'المنصورة → القاهرة',
    driverRating: 3,
    vehicleRating: 3,
    routeRating: 3,
    comment: 'رحلة عادية.',
    createdAt: _now.subtract(const Duration(days: 4)),
  ),
];

List<SupportTicket> _tickets() {
  final now = _now;
  return [
    SupportTicket(
      id: 'tk1',
      ticketNumber: 'TCK-3301',
      clientId: 'client-1',
      clientName: 'رامي عز الدين',
      clientPhone: '01000001234',
      category: 'تأخير رحلة',
      title: 'الحافلة تأخرت أكثر من ساعة',
      description: 'كنت في انتظار الحافلة منذ الساعة السابعة ولم تصل بعد.',
      priority: TicketPriority.urgent,
      status: TicketStatus.submitted,
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    ),
    SupportTicket(
      id: 'tk2',
      ticketNumber: 'TCK-3298',
      clientId: 'client-2',
      clientName: 'دينا أشرف',
      clientPhone: '01000005678',
      category: 'استرداد أموال',
      title: 'استرداد مبلغ لم يتم رغم الإلغاء',
      description: 'ألغيت الحجز منذ ثلاثة أيام ولم يصلني الاسترداد.',
      priority: TicketPriority.high,
      status: TicketStatus.underReview,
      assignedAgentName: 'محمود يوسف',
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(hours: 10)),
    ),
    SupportTicket(
      id: 'tk3',
      ticketNumber: 'TCK-3290',
      clientId: 'client-3',
      clientName: 'عمر خالد',
      clientPhone: '01000009012',
      category: 'استفسار',
      title: 'سؤال عن موعد رحلة الغد',
      description: 'هل يمكن تأكيد ميعاد رحلة الغد الساعة السابعة؟',
      priority: TicketPriority.medium,
      status: TicketStatus.contacted,
      assignedAgentName: 'محمود يوسف',
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
    SupportTicket(
      id: 'tk4',
      ticketNumber: 'TCK-3270',
      clientId: 'client-4',
      clientName: 'ياسمين محمود',
      clientPhone: '01000003456',
      category: 'عام',
      title: 'استفسار عام عن الباقات',
      description: 'تم الرد والتوضيح.',
      priority: TicketPriority.low,
      status: TicketStatus.resolved,
      createdAt: now.subtract(const Duration(days: 6)),
      updatedAt: now.subtract(const Duration(days: 5)),
      resolvedAt: now.subtract(const Duration(days: 5)),
    ),
  ];
}

List<UserSubscription> _subscriptions() {
  final now = _now;
  return [
    UserSubscription(
      id: 'sub1',
      userId: 'u1',
      userName: 'منى عبد الرحمن',
      userPhone: '01001112222',
      packageId: 'pkg-monthly',
      packageName: 'باقة شهرية',
      routeId: 'route-1',
      routeLabel: 'القاهرة → الإسكندرية',
      type: SubscriptionType.monthly,
      price: 1580,
      currency: 'ج.م',
      totalRides: 30,
      usedRides: 0,
      remainingRides: 30,
      paidAmount: 0,
      remainingAmount: 1580,
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
      status: SubscriptionStatus.pendingPayment,
      createdAt: now.subtract(const Duration(hours: 3)),
      updatedAt: now.subtract(const Duration(hours: 3)),
    ),
    UserSubscription(
      id: 'sub2',
      userId: 'u2',
      userName: 'كريم الشاذلي',
      userPhone: '01002223333',
      packageId: 'pkg-10',
      packageName: '١٠ أيام عمل',
      routeId: 'route-2',
      routeLabel: 'طنطا → الإسكندرية',
      type: SubscriptionType.tenDaysMonthly,
      price: 850,
      currency: 'ج.م',
      totalRides: 20,
      usedRides: 0,
      remainingRides: 20,
      paidAmount: 0,
      remainingAmount: 850,
      startDate: now,
      endDate: now.add(const Duration(days: 10)),
      status: SubscriptionStatus.pendingPayment,
      createdAt: now.subtract(const Duration(hours: 20)),
      updatedAt: now.subtract(const Duration(hours: 20)),
    ),
    UserSubscription(
      id: 'sub3',
      userId: 'u3',
      userName: 'سارة مجدي',
      userPhone: '01003334444',
      packageId: 'pkg-monthly',
      packageName: 'باقة شهرية',
      routeId: 'route-1',
      routeLabel: 'القاهرة → الإسكندرية',
      type: SubscriptionType.monthly,
      price: 1580,
      currency: 'ج.م',
      totalRides: 30,
      usedRides: 12,
      remainingRides: 18,
      paidAmount: 1580,
      remainingAmount: 0,
      startDate: now.subtract(const Duration(days: 10)),
      endDate: now.add(const Duration(days: 20)),
      status: SubscriptionStatus.active,
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
    UserSubscription(
      id: 'sub4',
      userId: 'u4',
      userName: 'أحمد فتحي',
      userPhone: '01004445555',
      packageId: 'pkg-5',
      packageName: '٥ أيام عمل',
      routeId: 'route-3',
      routeLabel: 'القاهرة → المنصورة',
      type: SubscriptionType.fiveDays,
      price: 420,
      currency: 'ج.م',
      totalRides: 10,
      usedRides: 8,
      remainingRides: 2,
      paidAmount: 420,
      remainingAmount: 0,
      startDate: now.subtract(const Duration(days: 4)),
      endDate: now.add(const Duration(days: 2)),
      status: SubscriptionStatus.active,
      createdAt: now.subtract(const Duration(days: 4)),
      updatedAt: now.subtract(const Duration(hours: 6)),
    ),
    UserSubscription(
      id: 'sub5',
      userId: 'u5',
      userName: 'هبة سليمان',
      userPhone: '01005556666',
      packageId: 'pkg-3m',
      packageName: 'ثلاثة أشهر',
      routeId: 'route-1',
      routeLabel: 'الإسكندرية → القاهرة',
      type: SubscriptionType.threeMonths,
      price: 4200,
      currency: 'ج.م',
      totalRides: 90,
      usedRides: 90,
      remainingRides: 0,
      paidAmount: 4200,
      remainingAmount: 0,
      startDate: now.subtract(const Duration(days: 95)),
      endDate: now.subtract(const Duration(days: 5)),
      status: SubscriptionStatus.expired,
      createdAt: now.subtract(const Duration(days: 95)),
      updatedAt: now.subtract(const Duration(days: 5)),
    ),
  ];
}

List<OperationalAlert> _alerts() {
  final now = _now;
  return [
    OperationalAlert(
      id: 'al1',
      type: OperationalAlertType.general,
      title: 'تحديث بيانات المكتب',
      body: 'تم تحديث ساعات العمل بنجاح.',
      isRead: false,
      priority: OperationalAlertPriority.low,
      createdAt: now.subtract(const Duration(minutes: 2)),
    ),
    OperationalAlert(
      id: 'al2',
      type: OperationalAlertType.refundRequest,
      title: 'طلب استرداد جديد',
      body: 'راكب طلب استرداد مبلغ حجز ملغى.',
      isRead: false,
      priority: OperationalAlertPriority.high,
      createdAt: now.subtract(const Duration(minutes: 40)),
    ),
    OperationalAlert(
      id: 'al3',
      type: OperationalAlertType.tripCancelled,
      title: 'تم إلغاء رحلة',
      body: 'رحلة القاهرة → الزقازيق الساعة ٩:٠٠ تم إلغاؤها.',
      isRead: false,
      priority: OperationalAlertPriority.normal,
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    OperationalAlert(
      id: 'al4',
      type: OperationalAlertType.captainRequest,
      title: 'طلب انضمام كابتن جديد',
      body: 'ياسر حسني تقدم بطلب انضمام ككابتن.',
      isRead: false,
      priority: OperationalAlertPriority.normal,
      createdAt: now.subtract(const Duration(hours: 5)),
    ),
    OperationalAlert(
      id: 'al5',
      type: OperationalAlertType.paymentReview,
      title: 'تم استلام إيصال دفع جديد',
      body: 'إيصال دفع لحجز رقم BK-100207 بانتظار المراجعة.',
      isRead: true,
      priority: OperationalAlertPriority.normal,
      createdAt: now.subtract(const Duration(hours: 8)),
    ),
    OperationalAlert(
      id: 'al6',
      type: OperationalAlertType.supportTicket,
      title: 'تم إغلاق شكوى',
      body: 'شكوى ياسمين محمود تم حلها وإغلاقها.',
      isRead: true,
      priority: OperationalAlertPriority.low,
      createdAt: now.subtract(const Duration(days: 1, hours: 3)),
    ),
  ];
}

DashboardHomeSummary _summary() => DashboardHomeSummary(
  trips: _trips(),
  bookings: _bookings(),
  revenue: _revenue,
  fleet: _fleet(),
  captainRequests: _captainRequests(),
  reviews: _reviews(),
  tickets: _tickets(),
  subscriptions: _subscriptions(),
);

// ─────────────────────────────────────────────────────────────────────────
// Capture plumbing.
// ─────────────────────────────────────────────────────────────────────────

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required bool dark,
  required double width,
  required double height,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final homeCubit = _StaticHomeCubit(DashboardHomeLoaded(_summary()));
  addTearDown(homeCubit.close);
  final alertsCubit = _StaticAlertsCubit(OperationalAlertsLoaded(_alerts()));
  addTearDown(alertsCubit.close);

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
            body: MultiBlocProvider(
              providers: [
                BlocProvider<DashboardHomeCubit>.value(value: homeCubit),
                BlocProvider<OperationalAlertsCubit>.value(value: alertsCubit),
              ],
              child: const DashboardHomeScreen(office: _office),
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
/// the glyphs differ. Light mode goes through [AppSurfaceStyle.dashboardLight]
/// — the factory this whole audit exists to judge — while dark keeps the
/// existing flat treatment for comparison only.
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

class _StaticHomeCubit extends Cubit<DashboardHomeState>
    implements DashboardHomeCubit {
  _StaticHomeCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StaticAlertsCubit extends Cubit<OperationalAlertsState>
    implements OperationalAlertsCubit {
  _StaticAlertsCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
