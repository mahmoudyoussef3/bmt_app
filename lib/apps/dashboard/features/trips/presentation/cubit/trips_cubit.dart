import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/operation_trip.dart';
import '../../domain/usecases/get_operation_trips_usecase.dart';
import '../../domain/usecases/update_trip_status_usecase.dart';
import 'trips_state.dart';

class TripsCubit extends Cubit<TripsState> {
  final GetOperationTripsUseCase _getTrips;
  final UpdateTripStatusUseCase _updateTripStatus;

  TripsCubit({
    required GetOperationTripsUseCase getTrips,
    required UpdateTripStatusUseCase updateTripStatus,
  }) : _getTrips = getTrips,
       _updateTripStatus = updateTripStatus,
       super(const TripsLoading());

  Future<void> load() async {
    emit(const TripsLoading());
    try {
      final trips = await _getTrips();
      emit(TripsLoaded(trips: trips));
    } catch (error) {
      emit(TripsError(error.toString()));
    }
  }

  void showDetails(OperationTrip trip) {
    final current = state;
    if (current is! TripsLoaded) return;
    emit(current.copyWith(selectedTrip: trip));
  }

  void closeDetails() {
    final current = state;
    if (current is! TripsLoaded) return;
    emit(current.copyWith(clearSelectedTrip: true));
  }

  Future<void> moveTrip(OperationTrip trip, OperationTripStatus status) async {
    final current = state;
    if (current is! TripsLoaded) return;
    try {
      final updated = await _updateTripStatus(trip.id, status);
      final trips = current.trips
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      emit(
        current.copyWith(
          trips: trips,
          selectedTrip: current.selectedTrip?.id == updated.id
              ? updated
              : current.selectedTrip,
        ),
      );
    } catch (error) {
      emit(TripsError(error.toString()));
    }
  }
}
