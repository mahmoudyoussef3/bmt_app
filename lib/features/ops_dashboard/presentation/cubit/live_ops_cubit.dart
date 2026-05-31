import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/trip_update.dart';
import '../../domain/models/driver_position.dart';
import '../../domain/models/trip_event.dart';
import '../../domain/repositories/trip_stream_repository.dart';
import '../../domain/repositories/driver_stream_repository.dart';
import '../../core/eventbus/live_event_bus.dart';
import 'live_ops_state.dart';

class LiveOpsCubit extends Cubit<LiveOpsState> {
  final TripStreamRepository tripRepo;
  final DriverStreamRepository driverRepo;
  final LiveEventBus eventBus;

  StreamSubscription<TripUpdate>? _tripSub;
  StreamSubscription<DriverPosition>? _driverSub;
  StreamSubscription<TripEvent>? _eventSub;

  final List<TripUpdate> _trips = [];
  final List<DriverPosition> _drivers = [];
  final List<TripEvent> _events = [];

  LiveOpsCubit({
    required this.tripRepo,
    required this.driverRepo,
    required this.eventBus,
  }) : super(LiveOpsLoading()) {
    _subscribe();
  }

  void _subscribe() {
    _tripSub = tripRepo.subscribeTripUpdates().listen((u) {
      final idx = _trips.indexWhere((t) => t.tripId == u.tripId);
      if (idx >= 0)
        _trips[idx] = u;
      else
        _trips.add(u);
      _emit();
    });

    _driverSub = driverRepo.subscribeDriverUpdates().listen((d) {
      final idx = _drivers.indexWhere((x) => x.driverId == d.driverId);
      if (idx >= 0)
        _drivers[idx] = d;
      else
        _drivers.add(d);
      _emit();
    });

    _eventSub = eventBus.stream.listen((e) {
      _events.insert(0, e);
      // keep recent 200 events
      if (_events.length > 200) _events.removeRange(200, _events.length);
      _emit();
    });
  }

  void _emit() => emit(
    LiveOpsLoaded(
      trips: List.from(_trips),
      drivers: List.from(_drivers),
      events: List.from(_events),
    ),
  );

  Future<void> cancelTrip(String tripId) async {
    await tripRepo.cancelTrip(tripId);
    eventBus.emit(
      TripEvent(
        id: 'EVT-${DateTime.now().microsecondsSinceEpoch}',
        tripId: tripId,
        type: EventType.incidentReported,
        severity: EventSeverity.warning,
        message: 'Trip $tripId cancelled by operator',
      ),
    );
  }

  Future<void> completeTrip(String tripId) async {
    await tripRepo.completeTrip(tripId);
    eventBus.emit(
      TripEvent(
        id: 'EVT-${DateTime.now().microsecondsSinceEpoch}',
        tripId: tripId,
        type: EventType.tripStarted,
        severity: EventSeverity.info,
        message: 'Trip $tripId marked completed',
      ),
    );
  }

  Future<void> reassignDriver(String tripId, String driverId) async {
    await tripRepo.reassignDriver(tripId, driverId);
    eventBus.emit(
      TripEvent(
        id: 'EVT-${DateTime.now().microsecondsSinceEpoch}',
        tripId: tripId,
        type: EventType.incidentReported,
        severity: EventSeverity.info,
        message: 'Trip $tripId reassigned to $driverId',
      ),
    );
  }

  @override
  Future<void> close() {
    _tripSub?.cancel();
    _driverSub?.cancel();
    _eventSub?.cancel();
    return super.close();
  }
}
