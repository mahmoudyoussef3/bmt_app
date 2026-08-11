import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/entities/passenger.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/usecases/get_trip_passengers_usecase.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/usecases/update_passenger_status_usecase.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/usecases/watch_trip_passengers_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/entities/trip_execution_state.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/mark_station_arrived_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/watch_trip_execution_snapshot_usecase.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_engine.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

import '../../domain/entities/captain_location_fix.dart';
import '../../domain/entities/location_gate.dart';
import '../../domain/entities/pickup_plan.dart';
import '../../domain/services/pickup_planner.dart';
import '../../domain/usecases/ensure_location_ready_usecase.dart';
import '../../domain/usecases/watch_captain_position_usecase.dart';
import 'captain_trip_map_state.dart';

class CaptainTripMapCubit extends Cubit<CaptainTripMapState> {
  CaptainTripMapCubit({
    required EnsureLocationReadyUseCase ensureLocationReady,
    required WatchCaptainPositionUseCase watchCaptainPosition,
    required GetTripPassengersUseCase getTripPassengers,
    required WatchTripPassengersUseCase watchTripPassengers,
    required UpdatePassengerStatusUseCase updatePassengerStatus,
    required WatchTripExecutionSnapshotUseCase watchTripSnapshot,
    required MarkStationArrivedUseCase markStationArrived,
  }) : _ensureLocationReady = ensureLocationReady,
       _watchCaptainPosition = watchCaptainPosition,
       _getTripPassengers = getTripPassengers,
       _watchTripPassengers = watchTripPassengers,
       _updatePassengerStatus = updatePassengerStatus,
       _watchTripSnapshot = watchTripSnapshot,
       _markStationArrived = markStationArrived,
       super(CaptainTripMapState.initial('', CaptainMapPhase.boarding));

  final EnsureLocationReadyUseCase _ensureLocationReady;
  final WatchCaptainPositionUseCase _watchCaptainPosition;
  final GetTripPassengersUseCase _getTripPassengers;
  final WatchTripPassengersUseCase _watchTripPassengers;
  final UpdatePassengerStatusUseCase _updatePassengerStatus;
  final WatchTripExecutionSnapshotUseCase _watchTripSnapshot;
  final MarkStationArrivedUseCase _markStationArrived;

  late AssignedTrip _trip;
  late RouteProgressEngine _engine;

  StreamSubscription<CaptainLocationFix>? _positionSub;
  StreamSubscription<void>? _passengersSub;
  StreamSubscription<TripExecutionSnapshot>? _snapshotSub;
  Timer? _ticker;

  List<Passenger> _passengers = const [];
  bool _hadFix = false;

  Future<void> start(AssignedTrip trip) async {
    _trip = trip;
    final phase = _phaseFrom(trip.status);
    _engine = _buildEngine(trip, phase);
    emit(CaptainTripMapState.initial(trip.id, phase));

    await _startLocation();
    _watchSnapshot(trip);
    await _loadPassengers();
    _watchPassengers(trip.id);
    _startTicker();
  }

  Future<void> _startLocation() async {
    final gate = await _ensureLocationReady();
    if (isClosed) return;
    if (!gate.isReady) {
      emit(
        state.copyWith(
          gpsHealth: GpsHealth.unavailable,
          gpsMessage: _gateMessage(gate),
        ),
      );
      return;
    }

    emit(state.copyWith(gpsHealth: GpsHealth.acquiring, gpsMessage: null));
    _positionSub?.cancel();
    _positionSub = _watchCaptainPosition().listen(
      _onFix,
      onError: (_) => _onLocationError(),
    );
  }

  void _onFix(CaptainLocationFix fix) {
    if (isClosed) return;
    _hadFix = true;
    final now = DateTime.now();
    _engine.addFix(
      latitude: fix.latitude,
      longitude: fix.longitude,
      speedKmh: fix.speedKmh,
      now: now,
    );
    final snapshot = _engine.snapshot(now);
    emit(
      state.copyWith(
        fix: fix,
        gpsHealth: GpsHealth.live,
        gpsMessage: null,
        progress: snapshot,
        activePickupProgress: _activePickupProgress(snapshot, state.pickup),
      ),
    );
  }

  void _onLocationError() {
    if (isClosed) return;
    emit(
      state.copyWith(
        gpsHealth: _hadFix ? GpsHealth.lost : GpsHealth.unavailable,
        gpsMessage: _hadFix
            ? 'انقطعت إشارة الموقع. تأكد من تفعيل خدمة الموقع.'
            : 'تعذّر تحديد موقعك. تأكد من تفعيل خدمة الموقع والصلاحية.',
      ),
    );
  }

  Future<void> retryLocation() => _startLocation();

  Future<void> _loadPassengers() async {
    try {
      _passengers = await _getTripPassengers(_trip.id);
      if (isClosed) return;
      _emitPlan();
    } catch (_) {}
  }

  void _watchPassengers(String tripId) {
    _passengersSub?.cancel();
    _passengersSub = _watchTripPassengers(
      tripId,
    ).listen((_) => _reloadPassengers());
  }

  Future<void> _reloadPassengers() async {
    try {
      final passengers = await _getTripPassengers(_trip.id);
      if (isClosed) return;
      _passengers = passengers;
      _emitPlan();
    } catch (_) {}
  }

  void _emitPlan() {
    final plan = PickupPlanner.plan(
      stops: _trip.stops,
      passengers: _passengers,
    );
    emit(
      state.copyWith(
        pickup: plan,
        activePickupProgress: _activePickupProgress(state.progress, plan),
        riderCount: plan.totalRiders,
        boardedCount: plan.totalBoarded,
      ),
    );
  }

  StopProgress? _activePickupProgress(
    RouteProgressSnapshot? snapshot,
    PickupPlan plan,
  ) => snapshot?.stopByName(plan.active?.name);

  void _watchSnapshot(AssignedTrip trip) {
    _snapshotSub?.cancel();
    _snapshotSub = _watchTripSnapshot(
      tripId: trip.id,
      routePointCount: trip.stops.length,
    ).listen(_onSnapshot, onError: (_) {});
  }

  void _onSnapshot(TripExecutionSnapshot snapshot) {
    if (isClosed) return;
    final phase = _phaseFrom(_statusToAssigned(snapshot.status));
    _engine.updatePhase(_progressPhase(phase));
    if (snapshot.arrivedStationsCount > 0) {
      _engine.seedVisited(snapshot.arrivedStationsCount);
    }

    if (phase.isFinished) _positionSub?.cancel();

    final progress = _engine.snapshot(DateTime.now());
    emit(
      state.copyWith(
        phase: phase,
        progress: progress,
        activePickupProgress: _activePickupProgress(progress, state.pickup),
        gpsHealth: phase.isFinished ? GpsHealth.unavailable : null,
        gpsMessage: phase.isFinished ? 'انتهت الرحلة' : null,
      ),
    );
  }

  Future<void> confirmBoarded(String tripPassengerId) =>
      _writeStatus(tripPassengerId, PassengerBoardingStatus.boarded);

  Future<void> markAbsent(String tripPassengerId) =>
      _writeStatus(tripPassengerId, PassengerBoardingStatus.absent);

  Future<void> markPending(String tripPassengerId) =>
      _writeStatus(tripPassengerId, PassengerBoardingStatus.pending);

  Future<void> _writeStatus(
    String tripPassengerId,
    PassengerBoardingStatus status,
  ) async {
    final rollback = _passengers;
    _passengers = [
      for (final p in _passengers)
        if (p.id == tripPassengerId) p.copyWith(status: status) else p,
    ];
    emit(state.copyWith(pendingRiderId: tripPassengerId, actionError: null));
    _emitPlan();

    try {
      await _updatePassengerStatus(
        tripPassengerId: tripPassengerId,
        status: status,
      );
      if (isClosed) return;
      emit(state.copyWith(pendingRiderId: null));
    } catch (error) {
      if (isClosed) return;
      _passengers = rollback;
      emit(state.copyWith(pendingRiderId: null, actionError: _readable(error)));
      _emitPlan();
    }
  }

  Future<void> markArrivedAtActivePickup() async {
    final active = state.pickup.active;
    if (active == null || active.stopId == null) return;
    emit(state.copyWith(arrivingStopId: active.stopId, actionError: null));
    try {
      await _markStationArrived(
        tripId: _trip.id,
        pointId: active.stopId!,
        pointName: active.name,
      );
      if (isClosed) return;
      emit(state.copyWith(arrivingStopId: null));
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(arrivingStopId: null, actionError: _readable(error)));
    }
  }

  void clearActionError() => emit(state.copyWith(actionError: null));

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) {
      if (isClosed || state.phase.isFinished) return;
      final progress = _engine.snapshot(DateTime.now());
      emit(
        state.copyWith(
          progress: progress,
          activePickupProgress: _activePickupProgress(progress, state.pickup),
        ),
      );
    });
  }

  RouteProgressEngine _buildEngine(AssignedTrip trip, CaptainMapPhase phase) {
    final stops = <RouteStop>[
      for (var i = 0; i < trip.stops.length; i++)
        RouteStop(
          id: trip.stops[i].id,
          name: trip.stops[i].name,
          latitude: trip.stops[i].latitude ?? 0,
          longitude: trip.stops[i].longitude ?? 0,
          order: i,
        ),
    ];
    return RouteProgressEngine(
      stops: stops,
      scheduledDeparture: trip.departureTime,
      scheduledArrival: trip.expectedArrivalTime,
      phase: _progressPhase(phase),
    );
  }

  CaptainMapPhase _phaseFrom(AssignedTripStatus status) => switch (status) {
    AssignedTripStatus.inProgress => CaptainMapPhase.underway,
    AssignedTripStatus.completed => CaptainMapPhase.completed,
    AssignedTripStatus.boarding => CaptainMapPhase.boarding,
    AssignedTripStatus.scheduled ||
    AssignedTripStatus.openForBooking => CaptainMapPhase.boarding,
  };

  AssignedTripStatus _statusToAssigned(TripExecutionStatus status) =>
      switch (status) {
        TripExecutionStatus.inProgress => AssignedTripStatus.inProgress,
        TripExecutionStatus.completed => AssignedTripStatus.completed,
        TripExecutionStatus.boarding => AssignedTripStatus.boarding,
        TripExecutionStatus.openForBooking => AssignedTripStatus.openForBooking,
        TripExecutionStatus.cancelled => AssignedTripStatus.completed,
        TripExecutionStatus.scheduled => AssignedTripStatus.scheduled,
      };

  TripProgressPhase _progressPhase(CaptainMapPhase phase) => switch (phase) {
    CaptainMapPhase.boarding => TripProgressPhase.boarding,
    CaptainMapPhase.underway => TripProgressPhase.enRoute,
    CaptainMapPhase.completed ||
    CaptainMapPhase.cancelled => TripProgressPhase.completed,
  };

  String _gateMessage(LocationGate gate) => switch (gate) {
    LocationGate.serviceDisabled =>
      'خدمة الموقع متوقفة. فعّلها من إعدادات الهاتف.',
    LocationGate.denied => 'يلزم السماح بالوصول للموقع لعرض موقعك على الخريطة.',
    LocationGate.deniedForever =>
      'صلاحية الموقع مرفوضة نهائياً. فعّلها من إعدادات التطبيق.',
    LocationGate.ready => '',
  };

  String _readable(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception: ?'), '');

  @override
  Future<void> close() {
    _positionSub?.cancel();
    _passengersSub?.cancel();
    _snapshotSub?.cancel();
    _ticker?.cancel();
    return super.close();
  }
}
