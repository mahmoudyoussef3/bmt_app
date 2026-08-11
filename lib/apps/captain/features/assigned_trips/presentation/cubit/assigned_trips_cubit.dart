import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/assigned_trip.dart';
import '../../domain/usecases/get_assigned_trips_usecase.dart';
import '../../domain/usecases/get_seen_trip_ids_usecase.dart';
import '../../domain/usecases/mark_trips_seen_usecase.dart';
import '../../domain/usecases/watch_assigned_trips_usecase.dart';
import 'assigned_trips_state.dart';

class AssignedTripsCubit extends Cubit<AssignedTripsState> {
  AssignedTripsCubit({
    required GetAssignedTripsUseCase getAssignedTrips,
    required WatchAssignedTripsUseCase watchAssignedTrips,
    required GetSeenTripIdsUseCase getSeenTripIds,
    required MarkTripsSeenUseCase markTripsSeen,
  }) : _getAssignedTrips = getAssignedTrips,
       _watchAssignedTrips = watchAssignedTrips,
       _getSeenTripIds = getSeenTripIds,
       _markTripsSeen = markTripsSeen,
       super(const AssignedTripsLoading());

  final GetAssignedTripsUseCase _getAssignedTrips;
  final WatchAssignedTripsUseCase _watchAssignedTrips;
  final GetSeenTripIdsUseCase _getSeenTripIds;
  final MarkTripsSeenUseCase _markTripsSeen;
  StreamSubscription<void>? _subscription;
  Timer? _refreshDebounce;
  bool _refreshing = false;

  Set<String> _seenTripIds = const {};

  Future<void> load() async {
    emit(const AssignedTripsLoading());
    try {
      final results = await (_getAssignedTrips(), _getSeenTripIds()).wait;
      if (isClosed) return;
      final trips = results.$1;
      _seenTripIds = results.$2;
      emit(AssignedTripsLoaded(trips, newTripIds: _newTripIds(trips)));
      _subscribeToChanges();
    } catch (error) {
      if (isClosed) return;
      emit(AssignedTripsError(error.toString()));
    }
  }

  Future<bool> refresh() => _fetch(showProgress: true);

  Future<void> _backgroundRefresh() => _fetch(showProgress: false);

  Future<bool> _fetch({required bool showProgress}) async {
    if (_refreshing) return true;
    _refreshing = true;
    if (showProgress) _setRefreshing(true);
    try {
      final trips = await _getAssignedTrips();
      if (isClosed) return true;
      emit(AssignedTripsLoaded(trips, newTripIds: _newTripIds(trips)));
      return true;
    } catch (_) {
      if (showProgress) _setRefreshing(false);
      return false;
    } finally {
      _refreshing = false;
    }
  }

  void _setRefreshing(bool value) {
    final current = state;
    if (isClosed || current is! AssignedTripsLoaded) return;
    emit(current.copyWith(isRefreshing: value));
  }

  Future<void> acknowledgeNewTrips() async {
    final current = state;
    if (current is! AssignedTripsLoaded || current.newTripIds.isEmpty) return;

    final allIds = current.trips.map((t) => t.id).toSet();
    await _markTripsSeen(allIds);
    if (isClosed) return;
    _seenTripIds = allIds;
    emit(AssignedTripsLoaded(current.trips, newTripIds: const {}));
  }

  Set<String> _newTripIds(List<AssignedTrip> trips) {
    return trips.map((t) => t.id).toSet().difference(_seenTripIds);
  }

  void _subscribeToChanges() {
    _subscription?.cancel();
    _subscription = _watchAssignedTrips().listen((_) {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(
        const Duration(milliseconds: 250),
        _backgroundRefresh,
      );
    }, onError: (_) {});
  }

  @override
  Future<void> close() {
    _refreshDebounce?.cancel();
    _subscription?.cancel();
    return super.close();
  }
}
