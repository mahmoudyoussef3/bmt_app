import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_action_failure.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_passenger.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/formatters/station_labels.dart';

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

  List<Passenger> _allPassengers = const [];

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

  void toggleStatusFilter(PassengerBoardingStatus status) {
    _statusFilter = _statusFilter == status ? null : status;
    _emitIfLoaded();
  }

  /// [noShowReason] and [note] are only meaningful for
  /// [PassengerBoardingStatus.absent], where the reason is what makes the
  /// difference between a recorded no-show and a passenger quietly left behind.
  Future<void> updateStatus({
    required String tripPassengerId,
    required PassengerBoardingStatus status,
    NoShowReason? noShowReason,
    String? note,
  }) async {
    if (state is PassengerManifestLoading || state is PassengerManifestError) {
      return;
    }
    final rollback = _allPassengers;

    _allPassengers = [
      for (final p in _allPassengers)
        if (p.id == tripPassengerId) p.copyWith(status: status) else p,
    ];
    _emitLoaded();

    try {
      await _updatePassengerStatus(
        tripPassengerId: tripPassengerId,
        status: status,
        noShowReason: noShowReason,
        note: note,
      );
    } catch (e) {
      if (isClosed) return;
      _allPassengers = rollback;
      emit(
        PassengerManifestUpdateError(
          loaded: _buildLoaded(),
          message: _readableError(e),
        ),
      );
    }
  }

  /// A refused no-show comes back typed, so the manifest says the same thing the
  /// station screen would rather than surfacing a raw Postgres string.
  String _readableError(Object error) => error is StationActionException
      ? StationLabels.failure(error)
      : error.toString().replaceFirst(RegExp(r'^Exception: ?'), '');

  Future<void> _reload() async {
    final tripId = _tripId;
    if (tripId == null) return;
    try {
      final passengers = await _getTripPassengers(tripId);
      if (isClosed) return;
      _allPassengers = passengers;
      _emitLoaded();
    } catch (_) {}
  }

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

  PassengerCounts _counts() {
    var boarded = 0;
    var pending = 0;
    var absent = 0;
    var cancelled = 0;
    for (final p in _allPassengers) {
      switch (p.status) {
        case PassengerBoardingStatus.boarded:
          boarded++;
        case PassengerBoardingStatus.pending:
          pending++;
        case PassengerBoardingStatus.absent:
          absent++;
        case PassengerBoardingStatus.cancelled:
          cancelled++;
      }
    }
    return PassengerCounts(
      boarded: boarded,
      pending: pending,
      absent: absent,
      cancelled: cancelled,
      total: _allPassengers.length,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
