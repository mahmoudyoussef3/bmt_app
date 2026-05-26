import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/shared/models/models.dart';
import 'package:bmt_app/shared/mock_data/mock_data.dart';

part 'driver_trip_state.dart';

class DriverTripCubit extends Cubit<DriverTripState> {
  DriverTripCubit() : super(const DriverTripState()) {
    loadTrips();
  }

  void loadTrips() {
    // Simulate driver's assigned trips
    final trips = MockData.getUpcomingTrips();
    emit(DriverTripState(assignedTrips: trips));
  }

  void markArrived(String tripId) {
    final updatedTrips = state.assignedTrips.map((trip) {
      if (trip.id == tripId) {
        return trip.copyWith(status: TripStatus.inProgress);
      }
      return trip;
    }).toList();
    emit(DriverTripState(assignedTrips: updatedTrips));
  }

  void markBoarded(String tripId) {
    // In real app, would mark specific passenger as boarded
    emit(state);
  }

  void skipPassenger(String tripId) {
    // In real app, would mark passenger as skipped
    emit(state);
  }
}

extension on Trip {
  Trip copyWith({TripStatus? status}) {
    return Trip(
      id: id,
      vehicle: vehicle,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      departureTime: departureTime,
      estimatedArrival: estimatedArrival,
      availableSeats: availableSeats,
      price: price,
      status: status ?? this.status,
    );
  }
}
