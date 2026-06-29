import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip.dart';
import '../../domain/usecases/get_trip_details_usecase.dart';
import '../../domain/usecases/get_trips_usecase.dart';
import 'trips_state.dart';

class TripsCubit extends Cubit<TripsState> {
  TripsCubit({
    required GetTripsUseCase getTrips,
    required GetTripDetailsUseCase getTripDetails,
  }) : _getTrips = getTrips,
       _getTripDetails = getTripDetails,
       super(const TripsLoading());

  final GetTripsUseCase _getTrips;
  final GetTripDetailsUseCase _getTripDetails;

  Future<void> loadTrips() async {
    emit(const TripsLoading());
    try {
      final trips = await _getTrips();
      emit(TripsLoaded(trips: trips));
    } catch (error) {
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
      emit(TripsLoaded(trips: trips, selectedTrip: selectedTrip));
    } catch (error) {
      emit(TripsError(error.toString()));
    }
  }

  List<TripData> tripsForFilter(TripFilter filter, List<TripData> trips) {
    return trips.where((trip) => trip.status == filter.statusMatch).toList();
  }

  int countForFilter(TripFilter filter, List<TripData> trips) {
    return tripsForFilter(filter, trips).length;
  }
}
