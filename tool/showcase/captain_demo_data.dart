// Demo data for the Captain app screenshots. Invented captain, invented trips.
//
// Coordinates are real points on the Cairo → Alexandria desert road, because
// the map screen draws a real route line — everything else is invented.

import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/notifications/domain/entities/captain_notification.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/entities/passenger.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/cubit/passenger_manifest_state.dart';
import 'package:bmt_app/apps/captain/features/profile/domain/entities/driver_profile.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/entities/trip_execution_state.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/entities/trip_history_item.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/utils/trip_history_filters.dart';
import 'package:bmt_app/apps/captain/features/trip_map/domain/entities/captain_location_fix.dart';
import 'package:bmt_app/apps/captain/features/trip_map/domain/entities/pickup_plan.dart';
import 'package:bmt_app/apps/captain/features/trip_map/presentation/cubit/captain_trip_map_state.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';
import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

final DateTime now = DateTime.now();
final DateTime _midnight = DateTime(now.year, now.month, now.day);

DateTime _at(int hour, int minute) =>
    _midnight.add(Duration(hours: hour, minutes: minute));

const String captainName = 'أحمد علي حسن';
const String officeName = 'مكتب النيل للنقل';

// ── Stops ───────────────────────────────────────────────────────────────────

const List<AssignedTripStop> _stops = [
  AssignedTripStop(
    id: 'stop-1',
    name: 'موقف عبود',
    latitude: 30.0958,
    longitude: 31.2497,
  ),
  AssignedTripStop(
    id: 'stop-2',
    name: 'موقف المظلات',
    latitude: 30.1216,
    longitude: 31.2436,
  ),
  AssignedTripStop(
    id: 'stop-3',
    name: 'استراحة كيلو 100',
    latitude: 30.4521,
    longitude: 30.6118,
  ),
  AssignedTripStop(
    id: 'stop-4',
    name: 'موقف سموحة',
    latitude: 31.2156,
    longitude: 29.9553,
  ),
  AssignedTripStop(
    id: 'stop-5',
    name: 'موقف سيدي جابر',
    latitude: 31.2189,
    longitude: 29.9436,
  ),
];

// ── Assigned trips (the "today" tab) ────────────────────────────────────────

final AssignedTrip liveTrip = AssignedTrip(
  id: 'T-2423',
  route: 'القاهرة — الإسكندرية',
  vehicleNumber: 'تويوتا هايس',
  plateNumber: 'ن ص ٤٢٧',
  departureTime: _at(13, 0),
  expectedArrivalTime: _at(16, 15),
  stops: _stops,
  passengerCount: 11,
  boardedCount: 7,
  status: AssignedTripStatus.inProgress,
  arrivedStationsCount: 2,
);

final List<AssignedTrip> assignedTrips = [
  liveTrip,
  AssignedTrip(
    id: 'T-2431',
    route: 'الإسكندرية — القاهرة',
    vehicleNumber: 'تويوتا هايس',
    plateNumber: 'ن ص ٤٢٧',
    departureTime: _at(18, 30),
    expectedArrivalTime: _at(21, 45),
    stops: _stops.reversed.toList(),
    passengerCount: 9,
    boardedCount: 0,
    status: AssignedTripStatus.openForBooking,
  ),
];

// ── Trip execution ──────────────────────────────────────────────────────────

const TripExecutionSnapshot executionSnapshot = TripExecutionSnapshot(
  status: TripExecutionStatus.inProgress,
  passengerCount: 11,
  boardedCount: 7,
  arrivedStationsCount: 2,
);

/// The station board behind the live trip: two stops worked and left, the
/// vehicle now driving to the third. Kept consistent with
/// [executionSnapshot] — two stations arrived, seven of eleven riders aboard.
final StationBoard stationBoard = StationBoard([
  TripStation(
    id: 'st-1',
    name: _stops[0].name,
    sequence: 1,
    status: TripStationStatus.departed,
    expectedArrivalAt: _at(13, 0),
    expectedDepartureAt: _at(13, 10),
    actualArrivalAt: _at(13, 2),
    actualDepartureAt: _at(13, 12),
    expectedBoardings: 4,
    boardedCount: 4,
  ),
  TripStation(
    id: 'st-2',
    name: _stops[1].name,
    sequence: 2,
    status: TripStationStatus.departed,
    expectedArrivalAt: _at(13, 25),
    expectedDepartureAt: _at(13, 35),
    actualArrivalAt: _at(13, 27),
    actualDepartureAt: _at(13, 38),
    expectedBoardings: 3,
    boardedCount: 3,
  ),
  TripStation(
    id: 'st-3',
    name: _stops[2].name,
    sequence: 3,
    status: TripStationStatus.arriving,
    expectedArrivalAt: _at(14, 40),
    expectedDepartureAt: _at(14, 55),
    minDwell: const Duration(minutes: 15),
    expectedBoardings: 2,
    pendingCount: 2,
  ),
  TripStation(
    id: 'st-4',
    name: _stops[3].name,
    sequence: 4,
    status: TripStationStatus.upcoming,
    expectedArrivalAt: _at(15, 50),
    expectedDepartureAt: _at(15, 58),
    expectedBoardings: 2,
    pendingCount: 2,
  ),
  TripStation(
    id: 'st-5',
    name: _stops[4].name,
    sequence: 5,
    status: TripStationStatus.upcoming,
    expectedArrivalAt: _at(16, 15),
  ),
]);

// ── Passenger manifest ──────────────────────────────────────────────────────

const List<Passenger> _passengers = [
  Passenger(
    id: 'p-1',
    name: 'منى عبد الرحمن',
    seat: 'A3',
    pickupPoint: 'موقف عبود',
    destination: 'موقف سيدي جابر',
    pickupTime: '13:00',
    phone: '01000000001',
    status: PassengerBoardingStatus.boarded,
  ),
  Passenger(
    id: 'p-2',
    name: 'كريم مصطفى شحاتة',
    seat: 'A4',
    pickupPoint: 'موقف عبود',
    destination: 'موقف سموحة',
    pickupTime: '13:00',
    phone: '01000000002',
    status: PassengerBoardingStatus.boarded,
  ),
  Passenger(
    id: 'p-3',
    name: 'هبة سمير فتحي',
    seat: 'B1',
    pickupPoint: 'موقف عبود',
    destination: 'موقف سيدي جابر',
    pickupTime: '13:00',
    phone: '01000000003',
    status: PassengerBoardingStatus.boarded,
  ),
  Passenger(
    id: 'p-4',
    name: 'يوسف طارق العدل',
    seat: 'B2',
    pickupPoint: 'موقف المظلات',
    destination: 'موقف سيدي جابر',
    pickupTime: '13:25',
    phone: '01000000004',
    status: PassengerBoardingStatus.boarded,
  ),
  Passenger(
    id: 'p-5',
    name: 'سارة ماهر لطفي',
    seat: 'B3',
    pickupPoint: 'موقف المظلات',
    destination: 'موقف سموحة',
    pickupTime: '13:25',
    phone: '01000000005',
    status: PassengerBoardingStatus.boarded,
  ),
  Passenger(
    id: 'p-6',
    name: 'عمر حسام الدين',
    seat: 'C1',
    pickupPoint: 'موقف المظلات',
    destination: 'موقف سيدي جابر',
    pickupTime: '13:25',
    phone: '01000000006',
    status: PassengerBoardingStatus.boarded,
  ),
  Passenger(
    id: 'p-7',
    name: 'ندى أشرف زيدان',
    seat: 'C2',
    pickupPoint: 'موقف المظلات',
    destination: 'موقف سموحة',
    pickupTime: '13:25',
    phone: '01000000007',
    status: PassengerBoardingStatus.boarded,
  ),
  Passenger(
    id: 'p-8',
    name: 'محمود عادل السيد',
    seat: 'C3',
    pickupPoint: 'استراحة كيلو 100',
    destination: 'موقف سيدي جابر',
    pickupTime: '14:40',
    phone: '01000000008',
    status: PassengerBoardingStatus.pending,
  ),
  Passenger(
    id: 'p-9',
    name: 'إيمان رضا القاضي',
    seat: 'C4',
    pickupPoint: 'استراحة كيلو 100',
    destination: 'موقف سموحة',
    pickupTime: '14:40',
    phone: '01000000009',
    status: PassengerBoardingStatus.pending,
  ),
  Passenger(
    id: 'p-10',
    name: 'طارق فؤاد الشناوي',
    seat: 'D1',
    pickupPoint: 'استراحة كيلو 100',
    destination: 'موقف سيدي جابر',
    pickupTime: '14:40',
    phone: '01000000010',
    status: PassengerBoardingStatus.pending,
  ),
  Passenger(
    id: 'p-11',
    name: 'ليلى نبيل عبد العزيز',
    seat: 'D2',
    pickupPoint: 'موقف المظلات',
    destination: 'موقف سموحة',
    pickupTime: '13:25',
    phone: '01000000011',
    status: PassengerBoardingStatus.absent,
  ),
];

const List<Passenger> passengers = _passengers;

const PassengerCounts passengerCounts = PassengerCounts(
  boarded: 7,
  pending: 3,
  absent: 1,
  cancelled: 0,
  total: 11,
);

// ── Trip map ────────────────────────────────────────────────────────────────

const List<RouteStop> _routeStops = [
  RouteStop(
    id: 'stop-1',
    name: 'موقف عبود',
    latitude: 30.0958,
    longitude: 31.2497,
    order: 1,
  ),
  RouteStop(
    id: 'stop-2',
    name: 'موقف المظلات',
    latitude: 30.1216,
    longitude: 31.2436,
    order: 2,
  ),
  RouteStop(
    id: 'stop-3',
    name: 'استراحة كيلو 100',
    latitude: 30.4521,
    longitude: 30.6118,
    order: 3,
  ),
  RouteStop(
    id: 'stop-4',
    name: 'موقف سموحة',
    latitude: 31.2156,
    longitude: 29.9553,
    order: 4,
  ),
  RouteStop(
    id: 'stop-5',
    name: 'موقف سيدي جابر',
    latitude: 31.2189,
    longitude: 29.9436,
    order: 5,
  ),
];

/// The bus between the second stop and the rest house, which is where the
/// "next pickup" panel has something to say.
final CaptainLocationFix mapFix = CaptainLocationFix(
  latitude: 30.3187,
  longitude: 30.8642,
  recordedAt: now,
  heading: 298,
  speed: 24.4,
  accuracy: 8,
);

final RouteProgressSnapshot mapProgress = RouteProgressSnapshot(
  phase: TripProgressPhase.enRoute,
  hasVehicleFix: true,
  isStale: false,
  isOffRoute: false,
  routeFraction: 0.38,
  traveledMeters: 84200,
  totalRouteMeters: 221000,
  nextStopIndex: 2,
  stops: [
    StopProgress(
      stop: _routeStops[0],
      status: StopVisitStatus.departed,
      etaConfidence: EtaConfidence.none,
    ),
    StopProgress(
      stop: _routeStops[1],
      status: StopVisitStatus.departed,
      etaConfidence: EtaConfidence.none,
    ),
    StopProgress(
      stop: _routeStops[2],
      status: StopVisitStatus.next,
      remainingMeters: 31400,
      eta: now.add(const Duration(minutes: 27)),
      etaConfidence: EtaConfidence.live,
    ),
    StopProgress(
      stop: _routeStops[3],
      status: StopVisitStatus.upcoming,
      remainingMeters: 128600,
      eta: now.add(const Duration(minutes: 96)),
      etaConfidence: EtaConfidence.estimated,
    ),
    StopProgress(
      stop: _routeStops[4],
      status: StopVisitStatus.upcoming,
      remainingMeters: 136800,
      eta: now.add(const Duration(minutes: 104)),
      etaConfidence: EtaConfidence.estimated,
    ),
  ],
);

PickupRider _rider(Passenger p) => PickupRider(
  tripPassengerId: p.id,
  name: p.name,
  seat: p.seat,
  phone: p.phone,
  status: p.status,
);

final PickupPlan pickupPlan = PickupPlan(
  activeIndex: 2,
  stops: [
    PickupStop(
      name: 'موقف عبود',
      stopId: 'stop-1',
      stopIndex: 0,
      latitude: 30.0958,
      longitude: 31.2497,
      riders: _passengers.take(3).map(_rider).toList(),
    ),
    PickupStop(
      name: 'موقف المظلات',
      stopId: 'stop-2',
      stopIndex: 1,
      latitude: 30.1216,
      longitude: 31.2436,
      riders: _passengers.skip(3).take(4).map(_rider).toList(),
    ),
    PickupStop(
      name: 'استراحة كيلو 100',
      stopId: 'stop-3',
      stopIndex: 2,
      latitude: 30.4521,
      longitude: 30.6118,
      riders: _passengers.skip(7).take(3).map(_rider).toList(),
    ),
  ],
);

final CaptainTripMapState tripMap = CaptainTripMapState(
  tripId: 'T-2423',
  phase: CaptainMapPhase.underway,
  gpsHealth: GpsHealth.live,
  fix: mapFix,
  progress: mapProgress,
  pickup: pickupPlan,
  activePickupProgress: mapProgress.stops[2],
  riderCount: 11,
  boardedCount: 7,
);

// ── Trip history ────────────────────────────────────────────────────────────

TripHistoryItem _history({
  required String id,
  required String route,
  required int daysAgo,
  required int depHour,
  required int arrHour,
  required int passengers,
  required int boarded,
}) {
  final day = _midnight.subtract(Duration(days: daysAgo));
  return TripHistoryItem(
    id: id,
    route: route,
    tripDate: day,
    departureTime: day.add(Duration(hours: depHour)),
    arrivalTime: day.add(Duration(hours: arrHour, minutes: 15)),
    passengerCount: passengers,
    boardedCount: boarded,
    vehicleNumber: 'تويوتا هايس',
    plateNumber: 'ن ص ٤٢٧',
  );
}

final List<TripHistoryItem> historyTrips = [
  _history(
    id: 'T-2418',
    route: 'القاهرة — الإسكندرية',
    daysAgo: 0,
    depHour: 6,
    arrHour: 9,
    passengers: 13,
    boarded: 13,
  ),
  _history(
    id: 'T-2412',
    route: 'الإسكندرية — القاهرة',
    daysAgo: 1,
    depHour: 18,
    arrHour: 21,
    passengers: 12,
    boarded: 11,
  ),
  _history(
    id: 'T-2408',
    route: 'القاهرة — الإسكندرية',
    daysAgo: 1,
    depHour: 13,
    arrHour: 16,
    passengers: 14,
    boarded: 14,
  ),
  _history(
    id: 'T-2401',
    route: 'الإسكندرية — القاهرة',
    daysAgo: 3,
    depHour: 6,
    arrHour: 9,
    passengers: 10,
    boarded: 10,
  ),
  _history(
    id: 'T-2394',
    route: 'القاهرة — الإسكندرية',
    daysAgo: 4,
    depHour: 13,
    arrHour: 16,
    passengers: 14,
    boarded: 13,
  ),
  _history(
    id: 'T-2387',
    route: 'الإسكندرية — القاهرة',
    daysAgo: 6,
    depHour: 18,
    arrHour: 21,
    passengers: 11,
    boarded: 11,
  ),
  _history(
    id: 'T-2380',
    route: 'القاهرة — الإسكندرية',
    daysAgo: 9,
    depHour: 6,
    arrHour: 9,
    passengers: 12,
    boarded: 12,
  ),
];

final List<TripHistoryGroup> historyGroups = groupTripHistoryByPeriod(
  historyTrips,
);

// ── Profile ─────────────────────────────────────────────────────────────────

final DriverProfile driverProfile = DriverProfile(
  id: 'driver-1',
  name: captainName,
  phone: '01000000000',
  licenseNumber: 'DL-4417-2029',
  averageRating: 4.8,
  totalTrips: 486,
  totalPassengers: 5940,
  vehicleCode: 'V-12',
  plateNumber: 'ن ص ٤٢٧',
  vehicleModel: 'تويوتا هايس 2021',
  vehicleCapacity: 14,
  employeeCode: 'CPT-118',
  officeName: officeName,
  licenseExpiryDate: DateTime(now.year + 3, 4, 18),
  hireDate: DateTime(2021, 9, 12),
);

// ── Notifications ───────────────────────────────────────────────────────────

final List<CaptainNotification> notifications = [
  CaptainNotification(
    id: 'n-1',
    title: 'راكب جديد على رحلتك',
    body: 'تم حجز المقعد C3 من استراحة كيلو 100 إلى موقف سيدي جابر.',
    category: CaptainNotificationCategory.passenger,
    isRead: false,
    createdAt: now.subtract(const Duration(minutes: 12)),
  ),
  CaptainNotification(
    id: 'n-2',
    title: 'تعديل موعد رحلة المساء',
    body: 'رحلة الإسكندرية — القاهرة أصبحت 18:30 بدلاً من 18:00.',
    category: CaptainNotificationCategory.trip,
    isRead: false,
    createdAt: now.subtract(const Duration(hours: 2)),
    priority: CaptainNotificationPriority.high,
  ),
  CaptainNotification(
    id: 'n-3',
    title: 'تم اعتماد بلاغ العطل',
    body: 'استلمت الإدارة بلاغ ارتفاع حرارة المحرك وتم جدولة الصيانة.',
    category: CaptainNotificationCategory.system,
    isRead: true,
    createdAt: now.subtract(const Duration(hours: 20)),
  ),
  CaptainNotification(
    id: 'n-4',
    title: 'إسناد رحلة الغد',
    body: 'رحلة القاهرة — الإسكندرية 06:00 بمركبة ن ص ٤٢٧.',
    category: CaptainNotificationCategory.assignment,
    isRead: true,
    createdAt: now.subtract(const Duration(days: 1)),
  ),
];
