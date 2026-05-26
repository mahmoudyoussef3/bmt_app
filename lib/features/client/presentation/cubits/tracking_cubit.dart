import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/shared/models/models.dart';

part 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  TrackingCubit() : super(const TrackingState());

  void loadTracking(Trip trip) {
    // Simulate real-time tracking
    final vehicle = trip.vehicle;
    emit(
      TrackingState(
        trip: trip,
        vehicle: vehicle,
        driverName: vehicle.driver.name,
        driverPhone: vehicle.driver.phone,
        eta: trip.estimatedArrival,
        vehicleLat: trip.pickupLocation.latitude,
        vehicleLng: trip.pickupLocation.longitude,
      ),
    );
  }

  void simulateMovement() {
    // Simulate vehicle moving towards destination
    if (state.trip != null) {
      final currentLat = state.vehicleLat + 0.005;
      final currentLng = state.vehicleLng + 0.005;
      emit(state.copyWith(vehicleLat: currentLat, vehicleLng: currentLng));
    }
  }
}
