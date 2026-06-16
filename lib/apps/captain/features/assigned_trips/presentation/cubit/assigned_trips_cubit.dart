import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_assigned_trips_usecase.dart';
import '../../domain/usecases/watch_assigned_trips_usecase.dart';
import 'assigned_trips_state.dart';

class AssignedTripsCubit extends Cubit<AssignedTripsState> {
  AssignedTripsCubit({
    required GetAssignedTripsUseCase getAssignedTrips,
    required WatchAssignedTripsUseCase watchAssignedTrips,
  })  : _getAssignedTrips = getAssignedTrips,
        _watchAssignedTrips = watchAssignedTrips,
        super(const AssignedTripsLoading());

  final GetAssignedTripsUseCase _getAssignedTrips;
  final WatchAssignedTripsUseCase _watchAssignedTrips;
  StreamSubscription<void>? _subscription;

  Future<void> load() async {
    emit(const AssignedTripsLoading());
    try {
      final trips = await _getAssignedTrips();
      emit(AssignedTripsLoaded(trips));
      _subscribeToChanges();
    } catch (error) {
      emit(AssignedTripsError(error.toString()));
    }
  }

  Future<void> refresh() async {
    try {
      final trips = await _getAssignedTrips();
      emit(AssignedTripsLoaded(trips));
    } catch (_) {
      // Keep current state on silent refresh failure
    }
  }

  void _subscribeToChanges() {
    _subscription?.cancel();
    _subscription = _watchAssignedTrips().listen((_) => refresh());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
