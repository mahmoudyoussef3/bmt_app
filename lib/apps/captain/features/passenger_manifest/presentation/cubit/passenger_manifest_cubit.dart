import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/passenger.dart';
import '../../domain/usecases/get_trip_passengers_usecase.dart';
import '../../domain/usecases/update_passenger_status_usecase.dart';
import '../../domain/usecases/watch_trip_passengers_usecase.dart';
import 'passenger_manifest_state.dart';

class PassengerManifestCubit extends Cubit<PassengerManifestState> {
  PassengerManifestCubit({
    required GetTripPassengersUseCase getTripPassengers,
    required WatchTripPassengersUseCase watchTripPassengers,
    required UpdatePassengerStatusUseCase updatePassengerStatus,
  }) : _getTripPassengers = getTripPassengers,
       _watchTripPassengers = watchTripPassengers,
       _updatePassengerStatus = updatePassengerStatus,
       super(const PassengerManifestLoading());

  final GetTripPassengersUseCase _getTripPassengers;
  final WatchTripPassengersUseCase _watchTripPassengers;
  final UpdatePassengerStatusUseCase _updatePassengerStatus;
  StreamSubscription<void>? _subscription;
  String? _tripId;

  /// The whole manifest. The view only ever sees the filtered slice, but the
  /// tallies and the optimistic status write both need the full list.
  List<Passenger> _allPassengers = const [];

  /// Live view filters. They sit on the cubit so the realtime watch below can
  /// push a fresh manifest without resetting what the captain is looking at.
  String _search = '';
  PassengerBoardingStatus? _statusFilter;

  Future<void> load(String tripId) async {
    _tripId = tripId;
    emit(const PassengerManifestLoading());
    try {
      _allPassengers = await _getTripPassengers(tripId);
      if (isClosed) return;
      _emitLoaded();
      _subscription?.cancel();
      _subscription = _watchTripPassengers(tripId).listen((_) => _reload());
    } catch (error) {
      if (isClosed) return;
      emit(PassengerManifestError(error.toString()));
    }
  }

  void search(String query) {
    if (query == _search) return;
    _search = query;
    _emitIfLoaded();
  }

  /// Tapping the active filter clears it — the chips are a toggle, not a
  /// radio group.
  void toggleStatusFilter(PassengerBoardingStatus status) {
    _statusFilter = _statusFilter == status ? null : status;
    _emitIfLoaded();
  }

  Future<void> updateStatus({
    required String tripPassengerId,
    required PassengerBoardingStatus status,
  }) async {
    if (state is! PassengerManifestLoaded) return;
    final rollback = _allPassengers;

    // Optimistic: reflect the tap immediately, reconcile with the server after.
    _allPassengers = [
      for (final p in _allPassengers)
        if (p.id == tripPassengerId) p.copyWith(status: status) else p,
    ];
    _emitLoaded();

    try {
      await _updatePassengerStatus(
        tripPassengerId: tripPassengerId,
        status: status,
      );
    } catch (e) {
      if (isClosed) return;
      _allPassengers = rollback;
      emit(
        PassengerManifestUpdateError(
          loaded: _buildLoaded(),
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _reload() async {
    final tripId = _tripId;
    if (tripId == null) return;
    try {
      final passengers = await _getTripPassengers(tripId);
      if (isClosed) return;
      _allPassengers = passengers;
      _emitLoaded();
    } catch (_) {
      // A dropped realtime refresh keeps the current manifest on screen.
    }
  }

  /// Re-emits only while a manifest is on screen, so a filter tap can't
  /// resurrect a list over a loading or error view.
  void _emitIfLoaded() {
    if (state is PassengerManifestLoading || state is PassengerManifestError) {
      return;
    }
    _emitLoaded();
  }

  void _emitLoaded() => emit(_buildLoaded());

  PassengerManifestLoaded _buildLoaded() {
    return PassengerManifestLoaded(
      visiblePassengers: _visiblePassengers(),
      counts: _counts(),
      search: _search,
      statusFilter: _statusFilter,
    );
  }

  List<Passenger> _visiblePassengers() {
    final query = _search.trim().toLowerCase();
    return [
      for (final p in _allPassengers)
        if (_matchesFilter(p) && _matchesQuery(p, query)) p,
    ];
  }

  bool _matchesFilter(Passenger p) =>
      _statusFilter == null || p.status == _statusFilter;

  bool _matchesQuery(Passenger p, String query) {
    if (query.isEmpty) return true;
    return p.name.toLowerCase().contains(query) ||
        p.seat.toLowerCase().contains(query) ||
        p.pickupPoint.toLowerCase().contains(query);
  }

  /// One pass over the manifest instead of one pass per status — the view
  /// previously re-scanned the whole list four times on every keystroke.
  PassengerCounts _counts() {
    var boarded = 0;
    var pending = 0;
    var absent = 0;
    var late = 0;
    for (final p in _allPassengers) {
      switch (p.status) {
        case PassengerBoardingStatus.boarded:
          boarded++;
        case PassengerBoardingStatus.pending:
          pending++;
        case PassengerBoardingStatus.absent:
          absent++;
        case PassengerBoardingStatus.late:
          late++;
        case PassengerBoardingStatus.cancelled:
          break;
      }
    }
    return PassengerCounts(
      boarded: boarded,
      pending: pending,
      absent: absent,
      late: late,
      total: _allPassengers.length,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
