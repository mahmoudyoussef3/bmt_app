import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip.dart';
import '../../domain/usecases/get_trip_details_usecase.dart';
import '../../domain/usecases/get_trips_usecase.dart';
import '../../domain/usecases/watch_trips_usecase.dart';
import 'trips_state.dart';

class TripsCubit extends Cubit<TripsState> {
  TripsCubit({
    required GetTripsUseCase getTrips,
    required GetTripDetailsUseCase getTripDetails,
    required WatchTripsUseCase watchTrips,
  }) : _getTrips = getTrips,
       _getTripDetails = getTripDetails,
       _watchTrips = watchTrips,
       super(const TripsLoading());

  final GetTripsUseCase _getTrips;
  final GetTripDetailsUseCase _getTripDetails;
  final WatchTripsUseCase _watchTrips;
  StreamSubscription<void>? _tripChangesSubscription;
  Timer? _refreshDebounce;
  bool _refreshing = false;

  Future<void> loadTrips() async {
    emit(const TripsLoading());
    try {
      final trips = await _getTrips();
      if (isClosed) return;
      emit(TripsLoaded(trips: trips));
      _subscribeToChanges();
    } catch (error) {
      if (isClosed) return;
      emit(TripsError(error.toString()));
    }
  }

  Future<void> loadTripDetails(String? id) async {
    emit(const TripsLoading());
    try {
      final trips = await _getTrips();
      final selectedTrip = id == null || id.isEmpty
          ? trips.firstOrNull
          : await _getTripDetails(id);
      if (isClosed) return;
      emit(TripsLoaded(trips: trips, selectedTrip: selectedTrip));
      _subscribeToChanges();
    } catch (error) {
      if (isClosed) return;
      emit(TripsError(error.toString()));
    }
  }

  List<TripData> tripsForFilter(TripFilter filter, List<TripData> trips) {
    return trips.where((trip) => trip.status == filter.statusMatch).toList();
  }

  int countForFilter(TripFilter filter, List<TripData> trips) {
    return tripsForFilter(filter, trips).length;
  }

  void _subscribeToChanges() {
    if (_tripChangesSubscription != null) return;
    _tripChangesSubscription = _watchTrips().listen((_) {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(
        const Duration(milliseconds: 250),
        _refreshFromRealtime,
      );
    }, onError: (_) {});
  }

  Future<void> _refreshFromRealtime() async {
    if (_refreshing || isClosed) return;
    _refreshing = true;
    try {
      final trips = await _getTrips();
      if (isClosed) return;
      final current = state;
      if (current is! TripsLoaded) return;
      final selectedId = current.selectedTrip?.id;
      final selectedTrip = selectedId == null
          ? null
          : trips.where((trip) => trip.id == selectedId).firstOrNull;
      emit(TripsLoaded(trips: trips, selectedTrip: selectedTrip));
    } catch (_) {
      // A realtime refresh is best-effort; keep the last usable state.
    } finally {
      _refreshing = false;
    }
  }

  @override
  Future<void> close() {
    _refreshDebounce?.cancel();
    _tripChangesSubscription?.cancel();
    return super.close();
  }
}
