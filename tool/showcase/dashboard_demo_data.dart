// Demo data for the product-screenshot harness.
//
// Fictional office, fictional people, fictional money. Nothing here is read
// from or written to any database — the harness never initializes Supabase.
// Names, phones and plates are invented so a marketing screenshot can never
// leak a real customer, captain or office.
//
// Dates are anchored to `DateTime.now()` because several screens derive
// "today" from the wall clock (DashboardHomeSummary.todayTrips, Live Ops
// tracking health, finance periods). Fixed dates would render an empty today.

import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/domain/entities/business_overview.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/entities/captain_request.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/domain/entities/dashboard_home_summary.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart'
    as finance;
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_money_model.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/domain/entities/licensing_catalog.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/domain/entities/office_license.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/live_ops_snapshot.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/trip_incident.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/domain/entities/office_profile.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/entities/booking_payment_verification.dart';
import 'package:bmt_app/apps/dashboard/features/reports/domain/entities/report_entities.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/domain/entities/trip_review_entry.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/entities/complaint.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/refund_request.dart'
    as wallet;
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet_summary.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet_vocabulary.dart';

final DateTime now = DateTime.now();
final DateTime _midnight = DateTime(now.year, now.month, now.day);

DateTime todayAt(int hour, [int minute = 0]) =>
    _midnight.add(Duration(hours: hour, minutes: minute));

String _two(int n) => n.toString().padLeft(2, '0');
String _date(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
String _time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

// ── The fictional office ────────────────────────────────────────────────────

const String officeName = 'مكتب النيل للنقل';

const List<String> _routeNames = [
  'القاهرة — الإسكندرية',
  'القاهرة — الغردقة',
  'القاهرة — أسيوط',
  'المنصورة — القاهرة',
  'طنطا — القاهرة',
];

const List<String> _drivers = [
  'أحمد علي حسن',
  'محمد سعيد عبد الله',
  'خالد إبراهيم فؤاد',
  'مصطفى كامل رشدي',
  'عمرو شعبان زكي',
  'ياسر منصور طه',
];

const List<String> _vehicles = [
  'تويوتا هايس — ن ص ٤٢٧',
  'مرسيدس سبرنتر — ب ط ١٩٣',
  'هيونداي H1 — ق ر ٦٥٨',
  'تويوتا هايس — د ل ٣٠٢',
  'مرسيدس سبرنتر — س ع ٨٧٤',
];

const List<String> _passengers = [
  'منى عبد الرحمن',
  'كريم الشاذلي',
  'سارة مجدي',
  'طارق الديب',
  'نورهان فتحي',
  'أيمن الجندي',
  'هبة سليمان',
  'رامي عز الدين',
  'دينا الشربيني',
  'شريف نبيل',
  'ملك حسام',
  'زياد العدل',
];

/// Sequential, obviously-synthetic phone numbers in the Egyptian mobile format.
///
/// Written as one unbroken digit run on purpose: a grouped number ("0100 123
/// 4567") is three separate numeric runs to the bidi algorithm, which reorders
/// them right-to-left and renders the phone backwards.
String _phone(int i) =>
    '0100000${(i % 10000).toString().padLeft(4, '0')}';

/// Spreads [count] events evenly across the part of today that has already
/// happened, so a capture run at 04:00 still produces a populated "today"
/// instead of pushing everything into yesterday.
DateTime _todaySpread(int index, int count) {
  final elapsed = now.difference(_midnight);
  final step = elapsed ~/ (count + 1);
  return _midnight.add(step * (index + 1));
}

// ── Routes ──────────────────────────────────────────────────────────────────

final List<OperationRoute> routes = [
  OperationRoute(
    id: 'route-1',
    routeCode: 'CAI-ALX',
    name: _routeNames[0],
    startCity: 'القاهرة',
    endCity: 'الإسكندرية',
    duration: '3 س 15 د',
    distance: '220 كم',
    status: OperationRouteStatus.active,
    stations: const [
      RouteStation(
        id: 's1',
        name: 'موقف عبود',
        area: 'شبرا',
        arrivalOffset: '00:00',
        order: 0,
        estimatedArrivalTime: '06:00',
      ),
      RouteStation(
        id: 's2',
        name: 'الطريق الصحراوي — كم 28',
        area: 'الجيزة',
        arrivalOffset: '00:35',
        order: 1,
        estimatedArrivalTime: '06:35',
      ),
      RouteStation(
        id: 's3',
        name: 'مدخل وادي النطرون',
        area: 'البحيرة',
        arrivalOffset: '01:40',
        order: 2,
        estimatedArrivalTime: '07:40',
      ),
      RouteStation(
        id: 's4',
        name: 'موقف سيدي جابر',
        area: 'الإسكندرية',
        arrivalOffset: '03:15',
        order: 3,
        estimatedArrivalTime: '09:15',
      ),
    ],
    notes: const ['يُمنع الوقوف خارج المحطات المعتمدة'],
  ),
  OperationRoute(
    id: 'route-2',
    routeCode: 'CAI-HRG',
    name: _routeNames[1],
    startCity: 'القاهرة',
    endCity: 'الغردقة',
    duration: '6 س 30 د',
    distance: '460 كم',
    status: OperationRouteStatus.active,
    stations: const [
      RouteStation(
        id: 's5',
        name: 'موقف التجمع الخامس',
        area: 'القاهرة الجديدة',
        arrivalOffset: '00:00',
        order: 0,
        estimatedArrivalTime: '07:00',
      ),
      RouteStation(
        id: 's6',
        name: 'استراحة الزعفرانة',
        area: 'البحر الأحمر',
        arrivalOffset: '03:20',
        order: 1,
        estimatedArrivalTime: '10:20',
      ),
      RouteStation(
        id: 's7',
        name: 'موقف الغردقة الرئيسي',
        area: 'الغردقة',
        arrivalOffset: '06:30',
        order: 2,
        estimatedArrivalTime: '13:30',
      ),
    ],
    notes: const [],
  ),
  OperationRoute(
    id: 'route-3',
    routeCode: 'CAI-AST',
    name: _routeNames[2],
    startCity: 'القاهرة',
    endCity: 'أسيوط',
    duration: '5 س 45 د',
    distance: '375 كم',
    status: OperationRouteStatus.active,
    stations: const [
      RouteStation(
        id: 's8',
        name: 'موقف الملز',
        area: 'الجيزة',
        arrivalOffset: '00:00',
        order: 0,
        estimatedArrivalTime: '05:30',
      ),
      RouteStation(
        id: 's9',
        name: 'موقف بني سويف',
        area: 'بني سويف',
        arrivalOffset: '02:10',
        order: 1,
        estimatedArrivalTime: '07:40',
      ),
      RouteStation(
        id: 's10',
        name: 'موقف المنيا',
        area: 'المنيا',
        arrivalOffset: '03:55',
        order: 2,
        estimatedArrivalTime: '09:25',
      ),
      RouteStation(
        id: 's11',
        name: 'موقف أسيوط',
        area: 'أسيوط',
        arrivalOffset: '05:45',
        order: 3,
        estimatedArrivalTime: '11:15',
      ),
    ],
    notes: const [],
  ),
  OperationRoute(
    id: 'route-4',
    routeCode: 'MNF-CAI',
    name: _routeNames[3],
    startCity: 'المنصورة',
    endCity: 'القاهرة',
    duration: '2 س 30 د',
    distance: '135 كم',
    status: OperationRouteStatus.active,
    stations: const [
      RouteStation(
        id: 's12',
        name: 'موقف المنصورة',
        area: 'الدقهلية',
        arrivalOffset: '00:00',
        order: 0,
        estimatedArrivalTime: '06:15',
      ),
      RouteStation(
        id: 's13',
        name: 'موقف بنها',
        area: 'القليوبية',
        arrivalOffset: '01:15',
        order: 1,
        estimatedArrivalTime: '07:30',
      ),
      RouteStation(
        id: 's14',
        name: 'موقف رمسيس',
        area: 'القاهرة',
        arrivalOffset: '02:30',
        order: 2,
        estimatedArrivalTime: '08:45',
      ),
    ],
    notes: const [],
  ),
  OperationRoute(
    id: 'route-5',
    routeCode: 'TNT-CAI',
    name: _routeNames[4],
    startCity: 'طنطا',
    endCity: 'القاهرة',
    duration: '1 س 50 د',
    distance: '95 كم',
    status: OperationRouteStatus.paused,
    stations: const [
      RouteStation(
        id: 's15',
        name: 'موقف طنطا',
        area: 'الغربية',
        arrivalOffset: '00:00',
        order: 0,
        estimatedArrivalTime: '07:00',
      ),
      RouteStation(
        id: 's16',
        name: 'موقف رمسيس',
        area: 'القاهرة',
        arrivalOffset: '01:50',
        order: 1,
        estimatedArrivalTime: '08:50',
      ),
    ],
    notes: const ['موقوف مؤقتًا لإعادة تسعير المسار'],
  ),
];

// ── Trips ───────────────────────────────────────────────────────────────────

OperationTrip _trip({
  required String id,
  required int routeIndex,
  required DateTime at,
  required int capacity,
  required int booked,
  OperationTripStatus status = OperationTripStatus.scheduled,
  int driverIndex = 0,
  int vehicleIndex = 0,
}) {
  return OperationTrip(
    id: id,
    routeId: 'route-${routeIndex + 1}',
    route: _routeNames[routeIndex],
    routePoints: const [],
    driverId: 'driver-$driverIndex',
    driver: _drivers[driverIndex],
    vehicleId: 'vehicle-$vehicleIndex',
    vehicle: _vehicles[vehicleIndex],
    date: _date(at),
    departure: _time(at),
    arrival: '',
    status: status,
    capacity: capacity,
    seats: [
      for (var i = 0; i < capacity; i++)
        TripSeat(
          id: '$id-seat-$i',
          label: '${i + 1}',
          row: i ~/ 3,
          column: i % 3,
          state: i < booked ? TripSeatState.reserved : TripSeatState.available,
        ),
    ],
    passengers: const [],
    events: const [],
    notes: const [],
  );
}

final List<OperationTrip> trips = [
  _trip(
    id: 'T-2418',
    routeIndex: 0,
    at: todayAt(6),
    capacity: 14,
    booked: 14,
    status: OperationTripStatus.completed,
    driverIndex: 0,
    vehicleIndex: 0,
  ),
  _trip(
    id: 'T-2419',
    routeIndex: 3,
    at: todayAt(6, 15),
    capacity: 14,
    booked: 12,
    status: OperationTripStatus.completed,
    driverIndex: 3,
    vehicleIndex: 3,
  ),
  _trip(
    id: 'T-2420',
    routeIndex: 2,
    at: todayAt(5, 30),
    capacity: 16,
    booked: 15,
    status: OperationTripStatus.inProgress,
    driverIndex: 2,
    vehicleIndex: 2,
  ),
  _trip(
    id: 'T-2421',
    routeIndex: 1,
    at: todayAt(7),
    capacity: 14,
    booked: 11,
    status: OperationTripStatus.inProgress,
    driverIndex: 1,
    vehicleIndex: 1,
  ),
  _trip(
    id: 'T-2422',
    routeIndex: 0,
    at: todayAt(9, 30),
    capacity: 14,
    booked: 9,
    status: OperationTripStatus.boarding,
    driverIndex: 4,
    vehicleIndex: 4,
  ),
  _trip(
    id: 'T-2423',
    routeIndex: 0,
    at: todayAt(13),
    capacity: 14,
    booked: 6,
    status: OperationTripStatus.openForBooking,
    driverIndex: 0,
    vehicleIndex: 0,
  ),
  _trip(
    id: 'T-2424',
    routeIndex: 3,
    at: todayAt(15, 30),
    capacity: 14,
    booked: 4,
    status: OperationTripStatus.openForBooking,
    driverIndex: 5,
    vehicleIndex: 3,
  ),
  _trip(
    id: 'T-2425',
    routeIndex: 2,
    at: todayAt(18),
    capacity: 16,
    booked: 7,
    status: OperationTripStatus.openForBooking,
    driverIndex: 2,
    vehicleIndex: 2,
  ),
  _trip(
    id: 'T-2426',
    routeIndex: 1,
    at: todayAt(21),
    capacity: 14,
    booked: 3,
    status: OperationTripStatus.scheduled,
    driverIndex: 1,
    vehicleIndex: 1,
  ),
  _trip(
    id: 'T-2427',
    routeIndex: 0,
    at: todayAt(6).add(const Duration(days: 1)),
    capacity: 14,
    booked: 5,
    status: OperationTripStatus.openForBooking,
    driverIndex: 0,
    vehicleIndex: 0,
  ),
  _trip(
    id: 'T-2428',
    routeIndex: 3,
    at: todayAt(8).add(const Duration(days: 1)),
    capacity: 14,
    booked: 2,
    status: OperationTripStatus.scheduled,
    driverIndex: 3,
    vehicleIndex: 3,
  ),
];

// ── Bookings ────────────────────────────────────────────────────────────────

OperationBooking _booking({
  required String id,
  required int passengerIndex,
  required int routeIndex,
  required String seat,
  required double amount,
  required DateTime createdAt,
  BookingStatus status = BookingStatus.confirmed,
  PaymentStatus paymentStatus = PaymentStatus.approved,
  BookingPaymentMethod method = BookingPaymentMethod.card,
  String tripId = 'T-2423',
  String tripTime = '13:00',
}) {
  return OperationBooking(
    id: id,
    bookingNumber: id,
    clientId: 'client-$passengerIndex',
    passengerName: _passengers[passengerIndex],
    phone: _phone(passengerIndex),
    route: _routeNames[routeIndex],
    tripTime: tripTime,
    date: _date(createdAt),
    seat: seat,
    paymentMethod: method,
    status: status,
    paymentStatus: paymentStatus,
    paymentAmount: amount,
    packageName: '',
    createdAt: createdAt,
    tripDetails: BookingTripDetails(
      tripId: tripId,
      route: _routeNames[routeIndex],
      date: _date(createdAt),
      time: tripTime,
      vehicle: _vehicles[routeIndex % _vehicles.length],
      driver: _drivers[routeIndex % _drivers.length],
    ),
    notes: const [],
    timeline: const [],
  );
}

/// Fare by route, matching the route's distance band.
const List<double> _fares = [180, 420, 260, 120, 95];

const List<String> _departureTimes = [
  '06:00',
  '06:15',
  '05:30',
  '07:00',
  '09:30',
  '13:00',
  '15:30',
  '18:00',
];

final List<OperationBooking> bookings = [
  for (var i = 0; i < 22; i++)
    _booking(
      id: '${10406 + i}',
      passengerIndex: i % _passengers.length,
      routeIndex: i % 4,
      seat: '${String.fromCharCode(65 + i % 4)}${1 + i % 5}',
      amount: _fares[i % 4],
      createdAt: _todaySpread(21 - i, 22),
      status: i == 9 ? BookingStatus.cancelled : BookingStatus.confirmed,
      paymentStatus: switch (i) {
        0 || 1 || 2 => PaymentStatus.pending,
        9 => PaymentStatus.refunded,
        _ => PaymentStatus.approved,
      },
      method: switch (i % 4) {
        0 => BookingPaymentMethod.instaPay,
        1 => BookingPaymentMethod.card,
        2 => BookingPaymentMethod.vodafoneCash,
        _ => BookingPaymentMethod.cash,
      },
      tripId: 'T-24${18 + i % 8}',
      tripTime: _departureTimes[i % _departureTimes.length],
    ),
];

/// Today's collected fares, summed from the bookings above rather than typed in
/// — the console cross-checks the two on the executive tab, and a hand-written
/// figure that disagreed would read as a bug in the product.
final double _todayBookingRevenue = bookings
    .where((b) => b.paymentStatus == PaymentStatus.approved)
    .fold<double>(0, (sum, b) => sum + b.paymentAmount);

// ── Payment verifications ───────────────────────────────────────────────────

BookingPaymentVerification _verification({
  required String id,
  required int passengerIndex,
  required int routeIndex,
  required String amount,
  BookingVerificationStatus status = BookingVerificationStatus.pending,
}) {
  return BookingPaymentVerification(
    id: id,
    bookingId: id,
    customer: VerificationCustomer(
      name: _passengers[passengerIndex],
      phone: _phone(passengerIndex),
      email: '',
      profileStatus: 'موثق',
    ),
    trip: VerificationTrip(
      tripId: 'T-2423',
      route: _routeNames[routeIndex],
      date: _date(now),
      time: '13:00',
      vehicle: _vehicles[routeIndex % _vehicles.length],
      driver: _drivers[routeIndex % _drivers.length],
    ),
    selectedSeat: 'A1',
    seatState: VerificationSeatState.temporaryReserved,
    amount: amount,
    method: VerificationPaymentMethod.bankTransfer,
    referenceNumber: 'INS-$id',
    receiptTitle: 'إيصال تحويل',
    receiptMeta: '',
    status: status,
    notes: const [],
    history: const [],
  );
}

final List<BookingPaymentVerification> verifications = [
  _verification(id: '10428', passengerIndex: 0, routeIndex: 0, amount: '180 ج.م'),
  _verification(id: '10427', passengerIndex: 1, routeIndex: 1, amount: '420 ج.م'),
  _verification(id: '10419', passengerIndex: 9, routeIndex: 0, amount: '180 ج.م'),
];

// ── Fleet ───────────────────────────────────────────────────────────────────

FleetVehicle _vehicle(
  String id,
  String plate,
  String brand,
  String model,
  int year,
  int capacity,
  FleetVehicleStatus status,
) {
  return FleetVehicle(
    id: id,
    vehicleCode: id.toUpperCase(),
    plateNumber: plate,
    vehicleType: 'ميكروباص',
    brand: brand,
    model: model,
    manufactureYear: year,
    color: 'أبيض',
    capacity: capacity,
    seatLayoutType: 'standard',
    imageUrl: '',
    notes: '',
    status: status,
    seatConfiguration: const SeatConfiguration(rows: 5, columns: 3, seats: []),
    licenseExpiry: _date(now.add(const Duration(days: 210))),
    insuranceExpiry: _date(now.add(const Duration(days: 96))),
    inspectionExpiry: _date(now.add(const Duration(days: 41))),
  );
}

/// The plates the vehicle list is built from, so documents name the same buses.
const List<String> _fleetPlates = [
  'ن ص ٤٢٧',
  'ب ط ١٩٣',
  'ق ر ٦٥٨',
  'د ل ٣٠٢',
  'س ع ٨٧٤',
  'ع ح ٥١٦',
  'ط ك ٢٤٩',
  'ف م ٧٣٥',
];

final FleetWorkspace fleet = FleetWorkspace(
  drivers: [
    for (var i = 0; i < _drivers.length; i++)
      FleetDriver(
        id: 'driver-$i',
        employeeCode: 'DRV-${100 + i}',
        fullName: _drivers[i],
        phone: _phone(i),
        emergencyPhone: '',
        address: '',
        nationalId: '',
        profileImageUrl: '',
        licenseNumber: 'LIC-${45000 + i * 37}',
        licenseExpiryDate: _date(now.add(Duration(days: 120 + i * 55))),
        hireDate: _date(now.subtract(Duration(days: 400 + i * 90))),
        notes: '',
        status: i == 5 ? FleetDriverStatus.suspended : FleetDriverStatus.active,
        currentVehicleId: i < 5 ? 'veh-${i + 1}' : '',
      ),
  ],
  vehicles: [
    _vehicle('veh-1', 'ن ص ٤٢٧', 'تويوتا', 'هايس', 2021, 14, FleetVehicleStatus.active),
    _vehicle('veh-2', 'ب ط ١٩٣', 'مرسيدس', 'سبرنتر', 2022, 14, FleetVehicleStatus.active),
    _vehicle('veh-3', 'ق ر ٦٥٨', 'هيونداي', 'H1', 2020, 16, FleetVehicleStatus.active),
    _vehicle('veh-4', 'د ل ٣٠٢', 'تويوتا', 'هايس', 2019, 14, FleetVehicleStatus.active),
    _vehicle('veh-5', 'س ع ٨٧٤', 'مرسيدس', 'سبرنتر', 2023, 14, FleetVehicleStatus.active),
    _vehicle('veh-6', 'ع ح ٥١٦', 'تويوتا', 'هايس', 2022, 14, FleetVehicleStatus.active),
    _vehicle('veh-7', 'ط ك ٢٤٩', 'هيونداي', 'H1', 2021, 16, FleetVehicleStatus.active),
    _vehicle('veh-8', 'ف م ٧٣٥', 'مرسيدس', 'سبرنتر', 2018, 14, FleetVehicleStatus.maintenance),
  ],
  assignments: _assignments,
  documents: _fleetDocuments,
);

/// Five of the six drivers hold a bus; the suspended one deliberately does not,
/// so the workspace shows both a paired fleet and the gap it flags.
final List<FleetAssignment> _assignments = [
  for (var i = 0; i < 5; i++)
    FleetAssignment(
      id: 'assign-$i',
      driverId: 'driver-$i',
      vehicleId: 'veh-${i + 1}',
      assignedAt: _date(now.subtract(Duration(days: 30 + i * 12))),
      status: FleetAssignmentStatus.active,
    ),
];

/// One licence per driver and one per bus, plus the insurance and inspection
/// the operator actually tracks — with the two nearest expiries flagged.
final List<FleetDocument> _fleetDocuments = [
  for (var i = 0; i < _drivers.length; i++)
    FleetDocument(
      id: 'doc-drv-$i',
      type: FleetDocumentType.driverLicense,
      ownerId: 'driver-$i',
      ownerName: _drivers[i],
      referenceNumber: 'LIC-${45000 + i * 37}',
      expiryDate: _date(now.add(Duration(days: 120 + i * 55))),
      status: i == 0
          ? FleetDocumentStatus.expiringSoon
          : FleetDocumentStatus.valid,
    ),
  for (var i = 0; i < _fleetPlates.length; i++) ...[
    FleetDocument(
      id: 'doc-veh-lic-$i',
      type: FleetDocumentType.vehicleLicense,
      ownerId: 'veh-${i + 1}',
      ownerName: _fleetPlates[i],
      referenceNumber: 'VL-${7100 + i * 13}',
      expiryDate: _date(now.add(Duration(days: 210 - i * 9))),
      status: FleetDocumentStatus.valid,
    ),
    FleetDocument(
      id: 'doc-veh-ins-$i',
      type: FleetDocumentType.insurance,
      ownerId: 'veh-${i + 1}',
      ownerName: _fleetPlates[i],
      referenceNumber: 'INS-${3300 + i * 21}',
      expiryDate: _date(now.add(Duration(days: 96 - i * 7))),
      status: i == 7
          ? FleetDocumentStatus.expiringSoon
          : FleetDocumentStatus.valid,
    ),
  ],
];

// ── Finance ─────────────────────────────────────────────────────────────────

final finance.RevenueMetrics revenue = finance.RevenueMetrics(
  todayRevenue: _todayBookingRevenue,
  weeklyRevenue: 52180,
  monthlyRevenue: 214730,
  activeSubscriptions: 34,
  totalBookingsRevenue: 186420,
  totalSubscriptionsRevenue: 28310,
);

final List<finance.PaymentRecord> payments = [
  for (var i = 0; i < bookings.length; i++)
    finance.PaymentRecord(
      id: 'PAY-${bookings[i].id}',
      clientName: bookings[i].passengerName,
      tripCode: bookings[i].tripDetails.tripId,
      amount: bookings[i].paymentAmount,
      paymentMethod: switch (bookings[i].paymentMethod) {
        BookingPaymentMethod.cash => finance.FinancePaymentMethod.cash,
        BookingPaymentMethod.vodafoneCash => finance.FinancePaymentMethod.vodafoneCash,
        _ => finance.FinancePaymentMethod.card,
      },
      status: switch (bookings[i].paymentStatus) {
        PaymentStatus.pending => finance.PaymentStatus.pending,
        PaymentStatus.refunded => finance.PaymentStatus.refunded,
        _ => finance.PaymentStatus.success,
      },
      date: bookings[i].createdAt,
    ),
];

final List<finance.SubscriptionRecord> subscriptionRecords = [
  for (var i = 0; i < 6; i++)
    finance.SubscriptionRecord(
      id: 'SUB-${3100 + i}',
      clientName: _passengers[i],
      packageName: i.isEven ? 'باقة شهرية — 20 رحلة' : 'باقة أسبوعية — 8 رحلات',
      amount: i.isEven ? 2800 : 1200,
      createdAt: now.subtract(Duration(days: i * 3 + 1)),
      startDate: now.subtract(Duration(days: i * 3)),
      endDate: now.add(Duration(days: 30 - i * 3)),
      status: finance.SubscriptionStatus.active,
      remainingRides: 20 - i * 2,
      tripsCount: 20,
      tripsUsed: i * 2,
    ),
];

final List<finance.RefundRequest> financeRefunds = [
  finance.RefundRequest(
    id: 'RF-882',
    transactionId: 'PAY-10421',
    clientName: _passengers[7],
    amount: 260,
    date: now.subtract(const Duration(hours: 6)),
    status: finance.RefundStatus.pending,
    reason: 'إلغاء الرحلة من المكتب',
  ),
  finance.RefundRequest(
    id: 'RF-881',
    transactionId: 'PAY-10415',
    clientName: _passengers[2],
    amount: 180,
    date: now.subtract(const Duration(days: 1, hours: 3)),
    status: finance.RefundStatus.approved,
    reason: 'تأخير تجاوز الساعتين',
  ),
  finance.RefundRequest(
    id: 'RF-879',
    transactionId: 'PAY-10402',
    clientName: _passengers[5],
    amount: 120,
    date: now.subtract(const Duration(days: 3)),
    status: finance.RefundStatus.approved,
    reason: 'مقعد غير متاح',
  ),
];

final List<finance.FinanceLedgerEntry> ledger = finance.FinanceLedger.build(
  payments: payments,
  subscriptions: subscriptionRecords,
);

final WalletFinancePosition walletPosition = WalletFinancePosition(
  currentLiability: 12450,
  movements: [
    for (var i = 0; i < 5; i++)
      WalletMovement(
        date: now.subtract(Duration(days: i)),
        kind: WalletMovementKind.refund,
        amount: 900.0 - i * 90,
      ),
    for (var i = 0; i < 4; i++)
      WalletMovement(
        date: now.subtract(Duration(days: i)),
        kind: WalletMovementKind.cashback,
        amount: 240.0 - i * 30,
      ),
    for (var i = 0; i < 3; i++)
      WalletMovement(
        date: now.subtract(Duration(days: i)),
        kind: WalletMovementKind.walletSpend,
        amount: -(320.0 + i * 40),
      ),
  ],
  refunds: [
    for (var i = 0; i < 3; i++)
      SettledRefund(
        settledAt: now.subtract(Duration(days: i * 2)),
        amount: 260.0 - i * 60,
        toWallet: i != 1,
      ),
  ],
);

// ── Wallet ──────────────────────────────────────────────────────────────────

final WalletOverview walletOverview = WalletOverview(
  outstandingBalance: 12450,
  walletCount: 148,
  fundedWalletCount: 96,
  frozenCount: 2,
  cashbackTotal: 6380,
  creditTotal: 2140,
  debitTotal: 870,
  refundTotal: 18240,
  refundWalletTotal: 11600,
  pendingRefundCount: 4,
  pendingRefundAmount: 780,
  generatedAt: now,
);

final WalletDirectoryPage walletDirectory = WalletDirectoryPage(
  total: 148,
  rows: [
    for (var i = 0; i < _passengers.length; i++)
      WalletDirectoryEntry(
        clientId: 'client-$i',
        fullName: _passengers[i],
        phone: _phone(i),
        balance: <double>[420, 260, 0, 180, 95, 640, 0, 320, 55, 210, 0, 130][i],
        walletStatus: i == 6 ? WalletStatus.frozen : WalletStatus.active,
        entryCount: 4 + i * 2,
        pendingRefunds: i == 0 ? 1 : 0,
        lastActivityAt: now.subtract(Duration(hours: 3 + i * 7)),
      ),
  ],
);

final WalletSummary walletSummary = WalletSummary(
  customer: WalletCustomer(
    id: 'client-0',
    fullName: _passengers[0],
    phone: _phone(0),
  ),
  wallet: const Wallet(
    exists: true,
    id: 'w-1',
    balance: 420,
    availableBalance: 420,
    status: WalletStatus.active,
    entryCount: 9,
    lifetimeCredited: 1240,
    lifetimeDebited: 820,
    lastSeq: 9,
  ),
  totalsByKind: const {
    WalletKind.refund: 620,
    WalletKind.cashback: 380,
    WalletKind.manualDebit: 120,
  },
  pendingRefunds: const [],
  entries: [
    for (var i = 0; i < 6; i++)
      WalletTransaction(
        id: 'wt-$i',
        seq: 9 - i,
        kind: i.isEven ? WalletKind.refund : WalletKind.cashback,
        category: i.isEven ? 'trip_cancelled' : 'promotion',
        source: WalletSource.dashboard,
        amount: 120.0 - i * 10,
        balanceBefore: 300.0 + i * 20,
        balanceAfter: 420.0 + i * 10,
        status: WalletEntryStatus.posted,
        reason: i.isEven ? 'استرداد قيمة حجز ملغى' : 'كاش باك على باقة شهرية',
        performedByName: 'مشغّل المكتب',
        createdAt: now.subtract(Duration(days: i, hours: 2)),
        clientId: 'client-0',
        clientName: _passengers[0],
        bookingNumber: '${10420 - i}',
      ),
  ],
);

final List<wallet.RefundRequest> walletRefundQueue = [
  for (var i = 0; i < 4; i++)
    wallet.RefundRequest(
      id: 'wr-$i',
      clientId: 'client-$i',
      clientName: _passengers[i],
      bookingId: 'b-$i',
      bookingNumber: '${10428 - i}',
      amount: <double>[260, 180, 120, 220][i],
      currency: 'EGP',
      status: RefundStatus.pending,
      category: 'trip_cancelled',
      reason: 'إلغاء الرحلة',
      source: 'client',
      createdAt: now.subtract(Duration(hours: 4 + i * 9)),
    ),
];

// ── Subscriptions, tickets, reviews, captain requests ───────────────────────

final List<UserSubscription> subscriptions = [
  for (var i = 0; i < 8; i++)
    UserSubscription(
      id: 'SUB-${3100 + i}',
      userId: 'client-$i',
      userName: _passengers[i],
      userPhone: _phone(i),
      packageId: 'pkg-${i % 2}',
      packageName: i.isEven ? 'باقة شهرية — 20 رحلة' : 'باقة أسبوعية — 8 رحلات',
      routeId: 'route-${(i % 3) + 1}',
      routeLabel: _routeNames[i % 3],
      originTripId: 'T-24${18 + i}',
      type: i.isEven ? SubscriptionType.monthly : SubscriptionType.fiveDays,
      price: i.isEven ? 2800 : 1200,
      currency: 'ج.م',
      totalRides: i.isEven ? 20 : 8,
      usedRides: i.isEven ? 20 - (i + 3) : 8 - (i % 5) - 1,
      remainingRides: i.isEven ? i + 3 : (i % 5) + 1,
      startDate: now.subtract(Duration(days: 12 + i)),
      endDate: now.add(Duration(days: 18 - i)),
      status: i == 7 ? SubscriptionStatus.expired : SubscriptionStatus.active,
      createdAt: now.subtract(Duration(days: 13 + i)),
      updatedAt: now.subtract(Duration(days: i)),
    ),
];

final List<SupportTicket> tickets = [
  SupportTicket(
    id: 'TK-512',
    ticketNumber: 'TK-512',
    clientId: 'client-3',
    clientName: _passengers[3],
    clientPhone: _phone(3),
    category: 'تأخير رحلة',
    title: 'الرحلة تأخرت 40 دقيقة عن الموعد',
    description: '',
    priority: TicketPriority.high,
    status: TicketStatus.submitted,
    createdAt: now.subtract(const Duration(hours: 2)),
    updatedAt: now.subtract(const Duration(hours: 2)),
  ),
  SupportTicket(
    id: 'TK-511',
    ticketNumber: 'TK-511',
    clientId: 'client-8',
    clientName: _passengers[8],
    clientPhone: _phone(8),
    category: 'استرداد',
    title: 'لم يصل مبلغ الاسترداد للمحفظة',
    description: '',
    priority: TicketPriority.medium,
    status: TicketStatus.underReview,
    createdAt: now.subtract(const Duration(hours: 20)),
    updatedAt: now.subtract(const Duration(hours: 5)),
  ),
  SupportTicket(
    id: 'TK-509',
    ticketNumber: 'TK-509',
    clientId: 'client-1',
    clientName: _passengers[1],
    clientPhone: _phone(1),
    category: 'مقعد',
    title: 'طلب تغيير المقعد قبل الرحلة',
    description: '',
    priority: TicketPriority.low,
    status: TicketStatus.resolved,
    createdAt: now.subtract(const Duration(days: 2)),
    updatedAt: now.subtract(const Duration(days: 1)),
  ),
];

final List<TripReviewEntry> reviews = [
  for (var i = 0; i < 9; i++)
    TripReviewEntry(
      id: 'rev-$i',
      bookingId: 'b-$i',
      bookingNumber: '${10420 - i}',
      clientName: _passengers[i],
      driverName: _drivers[i % _drivers.length],
      vehicleName: _vehicles[i % _vehicles.length],
      routeLabel: _routeNames[i % _routeNames.length],
      driverRating: [5, 5, 4, 5, 3, 5, 4, 5, 2][i],
      vehicleRating: [5, 4, 4, 5, 4, 5, 5, 4, 3][i],
      routeRating: [5, 5, 5, 4, 3, 5, 4, 5, 3][i],
      comment: [
        'كابتن محترم والرحلة كانت في معادها بالظبط.',
        'السيارة نظيفة والتكييف ممتاز.',
        '',
        'أفضل مكتب اتعاملت معاه على خط الإسكندرية.',
        'اتأخرنا شوية في التحميل بس الرحلة كويسة.',
        'الحجز من التطبيق سهل جدًا.',
        '',
        'الكابتن ساعدني في الشنط، شكرًا.',
        'الرحلة اتأخرت والمقعد كان مختلف عن الحجز.',
      ][i],
      createdAt: now.subtract(Duration(hours: 5 + i * 11)),
      driverId: 'driver-${i % _drivers.length}',
    ),
];

final List<CaptainRequest> captainRequests = [
  CaptainRequest(
    id: 'cr-1',
    fullName: 'سامح عبد المنعم',
    phone: _phone(4),
    status: CaptainRequestStatus.pending,
    createdAt: now.subtract(const Duration(hours: 8)),
  ),
  CaptainRequest(
    id: 'cr-2',
    fullName: 'وائل السيد',
    phone: _phone(6),
    status: CaptainRequestStatus.pending,
    createdAt: now.subtract(const Duration(days: 1, hours: 4)),
  ),
];

// ── Office profile ──────────────────────────────────────────────────────────

final OfficeProfile officeProfile = OfficeProfile(
  id: 'office-1',
  name: officeName,
  slug: 'nile-transport',
  description:
      'خدمة نقل جماعي بين المحافظات منذ 2016 — رحلات يومية مجدولة بأسطول مكيّف '
      'وكباتن معتمدين.',
  serviceAreas: const ['القاهرة', 'الجيزة', 'الإسكندرية', 'الدقهلية', 'الغردقة'],
  status: 'active',
  listingStatus: 'listed',
  rating: 4.7,
  ratingsCount: 1284,
  joinCode: 'NILE-2026',
  phone: '01000009001',
  email: 'ops@nile-transport.example',
  createdAt: DateTime(2016, 4, 12),
  updatedAt: now,
);

// ── Live Ops ────────────────────────────────────────────────────────────────

LiveTrip _liveTrip({
  required String id,
  required int routeIndex,
  required int driverIndex,
  required int vehicleIndex,
  required DateTime scheduled,
  required int capacity,
  required int booked,
  required bool inProgress,
  Duration? fixAge,
  double lat = 30.0444,
  double lng = 31.2357,
  DateTime? actualStart,
}) {
  return LiveTrip(
    id: id,
    statusLabel: inProgress ? 'جارية' : 'جاري التحميل',
    isInProgress: inProgress,
    routeName: _routeNames[routeIndex],
    driverName: _drivers[driverIndex],
    driverPhone: _phone(driverIndex),
    vehicleLabel: _vehicles[vehicleIndex],
    tripDate: _date(scheduled),
    departureTime: _time(scheduled),
    capacity: capacity,
    bookedSeats: booked,
    lastFix: fixAge == null
        ? null
        : LiveFix(
            latitude: lat,
            longitude: lng,
            heading: 315,
            speedKph: inProgress ? 86 : 0,
            recordedAt: now.subtract(fixAge),
          ),
    scheduledDeparture: scheduled,
    actualStart: actualStart,
  );
}

final LiveOpsSnapshot liveOps = LiveOpsSnapshot(
  activeTrips: [
    _liveTrip(
      id: 'T-2420',
      routeIndex: 2,
      driverIndex: 2,
      vehicleIndex: 2,
      scheduled: todayAt(5, 30),
      capacity: 16,
      booked: 15,
      inProgress: true,
      fixAge: const Duration(seconds: 24),
      lat: 28.7666,
      lng: 30.8018,
      actualStart: todayAt(5, 34),
    ),
    _liveTrip(
      id: 'T-2421',
      routeIndex: 1,
      driverIndex: 1,
      vehicleIndex: 1,
      scheduled: todayAt(7),
      capacity: 14,
      booked: 11,
      inProgress: true,
      fixAge: const Duration(seconds: 41),
      lat: 29.1547,
      lng: 32.5498,
      actualStart: todayAt(7, 6),
    ),
    _liveTrip(
      id: 'T-2422',
      routeIndex: 0,
      driverIndex: 4,
      vehicleIndex: 4,
      scheduled: todayAt(9, 30),
      capacity: 14,
      booked: 9,
      inProgress: false,
      fixAge: const Duration(minutes: 4),
      lat: 30.0626,
      lng: 31.2497,
    ),
    _liveTrip(
      id: 'T-2419',
      routeIndex: 3,
      driverIndex: 3,
      vehicleIndex: 3,
      scheduled: todayAt(6, 15),
      capacity: 14,
      booked: 12,
      inProgress: true,
      fixAge: const Duration(minutes: 3),
      lat: 30.4667,
      lng: 31.1833,
      actualStart: todayAt(6, 21),
    ),
  ],
  incidents: [
    TripIncident(
      id: 'inc-1',
      tripId: 'T-2421',
      type: IncidentType.routeBlockage,
      description: 'كثافة مرورية شديدة عند مدخل الزعفرانة — تأخير متوقع 25 دقيقة.',
      status: IncidentStatus.pending,
      createdAt: now.subtract(const Duration(minutes: 12)),
      routeName: _routeNames[1],
      driverName: _drivers[1],
      vehicleLabel: _vehicles[1],
      tripDate: _date(now),
      departureTime: '07:00',
    ),
    TripIncident(
      id: 'inc-2',
      tripId: 'T-2420',
      type: IncidentType.delay,
      description: 'وقوف إضافي بمحطة المنيا لنزول راكب.',
      status: IncidentStatus.acknowledged,
      createdAt: now.subtract(const Duration(minutes: 48)),
      acknowledgedAt: now.subtract(const Duration(minutes: 30)),
      routeName: _routeNames[2],
      driverName: _drivers[2],
      vehicleLabel: _vehicles[2],
      tripDate: _date(now),
      departureTime: '05:30',
    ),
    TripIncident(
      id: 'inc-3',
      tripId: 'T-2419',
      type: IncidentType.vehicleIssue,
      description: 'ضغط الإطار الخلفي منخفض — تم الفحص في استراحة بنها.',
      status: IncidentStatus.resolved,
      createdAt: now.subtract(const Duration(hours: 2, minutes: 10)),
      resolvedAt: now.subtract(const Duration(hours: 1, minutes: 40)),
      resolutionNote: 'تم ضبط الضغط ومتابعة الرحلة.',
      routeName: _routeNames[3],
      driverName: _drivers[3],
      vehicleLabel: _vehicles[3],
      tripDate: _date(now),
      departureTime: '06:15',
    ),
  ],
  generatedAt: now,
);

// ── Aggregates ──────────────────────────────────────────────────────────────

final BusinessOverview businessOverview = BusinessOverview(
  trips: trips,
  bookings: bookings,
  paymentVerifications: verifications,
  tickets: tickets,
  reviews: reviews,
  subscriptions: subscriptions,
  captainRequests: captainRequests,
  refundRequests: financeRefunds,
  fleet: fleet,
  revenue: revenue,
  wallet: walletPosition,
  liveOps: liveOps,
  generatedAt: now,
);

final DashboardHomeSummary homeSummary = DashboardHomeSummary(
  trips: trips,
  bookings: bookings,
  paymentVerifications: verifications,
  revenue: revenue,
  fleet: fleet,
  captainRequests: captainRequests,
  reviews: reviews,
  officeProfile: officeProfile,
  tickets: tickets,
  subscriptions: subscriptions,
);

// ── Reports ─────────────────────────────────────────────────────────────────

final ReportFilter reportFilter = ReportFilter(
  startDate: now.subtract(const Duration(days: 29)),
  endDate: now,
);

final ReportData tripsReport = ReportData(
  kpis: {
    'إجمالي الرحلات': '186',
    'متوسط الإشغال': '82%',
    'إجمالي الركاب': '2,140',
    'الإيراد': '214,730 ج.م',
  },
  rows: [
    for (var i = 0; i < 10; i++)
      TripReportRow(
        tripId: 'T-24${10 + i}',
        routeCode: ['CAI-ALX', 'CAI-HRG', 'CAI-AST', 'MNF-CAI'][i % 4],
        driverName: _drivers[i % _drivers.length],
        vehiclePlate: ['ن ص ٤٢٧', 'ب ط ١٩٣', 'ق ر ٦٥٨', 'د ل ٣٠٢'][i % 4],
        passengerCount: [14, 12, 16, 11, 14, 9, 13, 14, 10, 12][i],
        occupancyRate: [100, 86, 94, 79, 100, 64, 93, 100, 71, 86][i].toDouble(),
        revenue: <double>[2520, 5040, 4160, 1320, 2520, 3780, 2340, 2520, 2600, 1440][i],
        date: now.subtract(Duration(days: i)),
        status: i < 8 ? 'مكتملة' : 'ملغاة',
      ),
  ],
  trends: [
    for (var i = 13; i >= 0; i--)
      MapEntry(
        _date(now.subtract(Duration(days: i))),
        <double>[5200, 6100, 4800, 7300, 8100, 6900, 5400, 7700, 8600, 9200, 7100, 6400, 8900, 8460][13 - i],
      ),
  ],
  occupancyTrends: [
    for (var i = 13; i >= 0; i--)
      MapEntry(
        _date(now.subtract(Duration(days: i))),
        <double>[72, 78, 69, 84, 88, 81, 74, 86, 91, 94, 83, 77, 92, 82][13 - i],
      ),
  ],
);

// ── SaaS licensing ──────────────────────────────────────────────────────────
//
// The plan catalogue offices are licensed on. Prices are invented; the tier
// shape (a free-ish entry plan, two paid tiers, one archived) is the shape the
// licensing console is built to manage.

const List<LicensingPlan> licensingPlans = [
  LicensingPlan(
    id: 'plan-1',
    key: 'starter',
    nameAr: 'الباقة الأساسية',
    nameEn: 'Starter',
    taglineAr: 'مكتب واحد يبدأ بالحجوزات والرحلات.',
    status: 'active',
    isPublic: true,
    priceMonthly: 1500,
    priceYearly: 15000,
    trialDays: 14,
    officeCount: 9,
    featureCount: 18,
    revision: 4,
    sortOrder: 10,
  ),
  LicensingPlan(
    id: 'plan-2',
    key: 'growth',
    nameAr: 'باقة النمو',
    nameEn: 'Growth',
    taglineAr: 'أسطول وتتبّع مباشر ومحفظة عملاء.',
    status: 'active',
    isPublic: true,
    priceMonthly: 3500,
    priceYearly: 35000,
    trialDays: 14,
    downgradeToKey: 'starter',
    officeCount: 14,
    featureCount: 31,
    revision: 7,
    sortOrder: 20,
  ),
  LicensingPlan(
    id: 'plan-3',
    key: 'enterprise',
    nameAr: 'باقة المؤسسات',
    nameEn: 'Enterprise',
    taglineAr: 'تقارير تنفيذية وحدود مرتفعة ودعم مخصّص.',
    status: 'active',
    isPublic: true,
    priceMonthly: 7500,
    priceYearly: 78000,
    trialDays: 0,
    downgradeToKey: 'growth',
    officeCount: 4,
    featureCount: 47,
    revision: 3,
    sortOrder: 30,
  ),
  LicensingPlan(
    id: 'plan-4',
    key: 'legacy_pilot',
    nameAr: 'باقة التجربة (مؤرشفة)',
    nameEn: 'Pilot',
    taglineAr: 'مغلقة للاشتراكات الجديدة — المكاتب القائمة تعمل كما هي.',
    status: 'archived',
    priceMonthly: 900,
    officeCount: 2,
    featureCount: 12,
    revision: 1,
    sortOrder: 90,
  ),
];

const LicensingSettings licensingSettings = LicensingSettings(
  enforcementMode: 'enforcing',
  defaultSignupPlanKey: 'starter',
  graceDays: 7,
  warnDaysBefore: 14,
);
