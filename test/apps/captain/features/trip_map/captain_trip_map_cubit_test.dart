import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/entities/passenger.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/repositories/passenger_manifest_repository.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/usecases/get_trip_passengers_usecase.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/usecases/update_passenger_status_usecase.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/usecases/watch_trip_passengers_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/entities/trip_execution_state.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/repositories/trip_execution_repository.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/mark_station_arrived_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/watch_trip_execution_snapshot_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_map/domain/entities/captain_location_fix.dart';
import 'package:bmt_app/apps/captain/features/trip_map/domain/entities/location_gate.dart';
import 'package:bmt_app/apps/captain/features/trip_map/domain/repositories/captain_location_stream_repository.dart';
import 'package:bmt_app/apps/captain/features/trip_map/domain/usecases/ensure_location_ready_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_map/domain/usecases/watch_captain_position_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_map/presentation/cubit/captain_trip_map_cubit.dart';
import 'package:bmt_app/apps/captain/features/trip_map/presentation/cubit/captain_trip_map_state.dart';

void main() {
  late _FakeLocationRepo location;
  late _FakeManifestRepo manifest;
  late _FakeTripExecutionRepo execution;
  late CaptainTripMapCubit cubit;

  CaptainTripMapCubit build() => CaptainTripMapCubit(
    ensureLocationReady: EnsureLocationReadyUseCase(location),
    watchCaptainPosition: WatchCaptainPositionUseCase(location),
    getTripPassengers: GetTripPassengersUseCase(manifest),
    watchTripPassengers: WatchTripPassengersUseCase(manifest),
    updatePassengerStatus: UpdatePassengerStatusUseCase(manifest),
    watchTripSnapshot: WatchTripExecutionSnapshotUseCase(execution),
    markStationArrived: MarkStationArrivedUseCase(execution),
  );

  setUp(() {
    location = _FakeLocationRepo();
    manifest = _FakeManifestRepo();
    execution = _FakeTripExecutionRepo();
    cubit = build();
  });

  tearDown(() => cubit.close());

  test('a denied location gate leaves GPS unavailable with a reason', () async {
    location.gate = LocationGate.denied;
    await cubit.start(_trip());

    expect(cubit.state.gpsHealth, GpsHealth.unavailable);
    expect(cubit.state.gpsMessage, isNotNull);
    expect(location.subscribed, isFalse, reason: 'no feed without permission');
  });

  test('a position fix turns tracking live', () async {
    await cubit.start(_trip());
    expect(cubit.state.gpsHealth, GpsHealth.acquiring);

    location.emit(_fix(31.21, 29.91));
    await _settle();

    expect(cubit.state.gpsHealth, GpsHealth.live);
    expect(cubit.state.fix, isNotNull);
  });

  test('boarding the last pending rider promotes the next pickup stop',
      () async {
    manifest.passengers = [
      _rider('p1', 'محطة مصر', PassengerBoardingStatus.pending),
      _rider('p2', 'سيدي جابر', PassengerBoardingStatus.pending),
    ];
    await cubit.start(_trip());
    expect(cubit.state.pickup.active?.name, 'محطة مصر');

    await cubit.confirmBoarded('p1');

    expect(cubit.state.pickup.active?.name, 'سيدي جابر');
    expect(cubit.state.boardedCount, 1);
    expect(execution.arrivals, isEmpty);
  });

  test('a failed boarding write rolls back and keeps the same active pickup',
      () async {
    manifest.passengers = [
      _rider('p1', 'محطة مصر', PassengerBoardingStatus.pending),
    ];
    await cubit.start(_trip());
    manifest.failNextUpdate = true;

    await cubit.confirmBoarded('p1');

    expect(cubit.state.actionError, isNotNull);
    expect(cubit.state.pickup.active?.name, 'محطة مصر');
    expect(
      cubit.state.pickup.active?.riders.single.status,
      PassengerBoardingStatus.pending,
      reason: 'the rider reverts to pending after a rejected write',
    );
  });

  test('marking the active pickup arrived writes the shared station event',
      () async {
    manifest.passengers = [
      _rider('p1', 'محطة مصر', PassengerBoardingStatus.pending),
    ];
    await cubit.start(_trip());

    await cubit.markArrivedAtActivePickup();

    expect(execution.arrivals, [('s0', 'محطة مصر')]);
  });

  test('a completed trip stops tracking and reads as finished', () async {
    await cubit.start(_trip());
    location.emit(_fix(31.21, 29.91));
    await _settle();
    expect(cubit.state.gpsHealth, GpsHealth.live);

    execution.emit(_snapshot(TripExecutionStatus.completed));
    await _settle();

    expect(cubit.state.phase, CaptainMapPhase.completed);
    expect(cubit.state.gpsHealth, GpsHealth.unavailable);
    expect(location.cancelled, isTrue, reason: 'the sensor is released');
  });
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

AssignedTrip _trip() => AssignedTrip(
  id: 'trip-1',
  route: 'الإسكندرية',
  vehicleNumber: 'V1',
  plateNumber: 'أ ب ج 123',
  departureTime: DateTime(2026, 7, 26, 8),
  expectedArrivalTime: DateTime(2026, 7, 26, 10),
  stops: const [
    AssignedTripStop(id: 's0', name: 'محطة مصر', latitude: 31.20, longitude: 29.90),
    AssignedTripStop(id: 's1', name: 'سيدي جابر', latitude: 31.22, longitude: 29.94),
  ],
  passengerCount: 2,
  boardedCount: 0,
  status: AssignedTripStatus.boarding,
);

CaptainLocationFix _fix(double lat, double lng) => CaptainLocationFix(
  latitude: lat,
  longitude: lng,
  recordedAt: DateTime.now(),
  speed: 8,
);

Passenger _rider(String id, String pickup, PassengerBoardingStatus status) =>
    Passenger(
      id: id,
      name: 'راكب $id',
      seat: 'A1',
      pickupPoint: pickup,
      destination: 'سيدي جابر',
      pickupTime: '08:00',
      phone: '01000000000',
      status: status,
    );

TripExecutionSnapshot _snapshot(TripExecutionStatus status) =>
    TripExecutionSnapshot(
      status: status,
      passengerCount: 2,
      boardedCount: 0,
      arrivedStationsCount: 0,
    );

class _FakeLocationRepo implements CaptainLocationStreamRepository {
  LocationGate gate = LocationGate.ready;
  bool subscribed = false;
  bool cancelled = false;
  final _controller = StreamController<CaptainLocationFix>.broadcast();

  void emit(CaptainLocationFix fix) => _controller.add(fix);

  @override
  Future<LocationGate> ensureReady() async => gate;

  @override
  Stream<CaptainLocationFix> watchPosition() {
    subscribed = true;
    _controller.onCancel = () => cancelled = true;
    return _controller.stream;
  }
}

class _FakeManifestRepo implements PassengerManifestRepository {
  List<Passenger> passengers = const [];
  bool failNextUpdate = false;
  final _changes = StreamController<void>.broadcast();

  @override
  Future<List<Passenger>> getTripPassengers(String tripId) async => passengers;

  @override
  Stream<void> watchPassengerUpdates(String tripId) => _changes.stream;

  @override
  Future<void> updatePassengerStatus({
    required String tripPassengerId,
    required PassengerBoardingStatus status,
  }) async {
    if (failNextUpdate) {
      failNextUpdate = false;
      throw Exception('تعذر الاتصال بالخادم');
    }
    passengers = [
      for (final p in passengers)
        if (p.id == tripPassengerId) p.copyWith(status: status) else p,
    ];
  }
}

class _FakeTripExecutionRepo implements TripExecutionRepository {
  final arrivals = <(String, String)>[];
  final _snapshots = StreamController<TripExecutionSnapshot>.broadcast();

  void emit(TripExecutionSnapshot snapshot) => _snapshots.add(snapshot);

  @override
  Stream<TripExecutionSnapshot> watchTripSnapshot({
    required String tripId,
    required int routePointCount,
  }) => _snapshots.stream;

  @override
  Future<void> markStationArrived({
    required String tripId,
    required String pointId,
    required String pointName,
  }) async => arrivals.add((pointId, pointName));

  @override
  Future<TripExecutionStateData> startBoarding(String tripId) =>
      throw UnimplementedError();

  @override
  Future<TripExecutionStateData> startTrip(String tripId) =>
      throw UnimplementedError();

  @override
  Future<TripExecutionStateData> completeTrip(String tripId) =>
      throw UnimplementedError();
}
