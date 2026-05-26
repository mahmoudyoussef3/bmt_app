import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/shared/models/models.dart';
import 'package:bmt_app/shared/mock_data/mock_data.dart';

part 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  BookingCubit() : super(const BookingState());

  void selectPickupLocation(Location location) {
    emit(
      state.copyWith(pickupLocation: location, step: BookingStep.destination),
    );
  }

  void selectDestination(Location location) {
    emit(state.copyWith(destination: location, step: BookingStep.arrival));
  }

  void selectArrivalTime(DateTime time) {
    emit(state.copyWith(arrivalTime: time, step: BookingStep.vehicles));
  }

  void loadAvailableVehicles() {
    // Simulate loading available trips
    final trips = MockData.getUpcomingTrips();
    emit(state.copyWith(availableTrips: trips));
  }

  void selectVehicle(Trip trip) {
    emit(state.copyWith(selectedTrip: trip, step: BookingStep.seats));
  }

  void selectSeat(Seat seat) {
    final updatedSeat = seat.copyWith(status: SeatStatus.selected);
    emit(state.copyWith(selectedSeat: updatedSeat));
  }

  void confirmBooking() {
    final booking = Booking(
      id: 'book_${DateTime.now().millisecondsSinceEpoch}',
      user: MockData.currentUser,
      trip: state.selectedTrip!,
      seat: state.selectedSeat!,
      status: BookingStatus.confirmed,
      bookingDate: DateTime.now(),
      totalPrice: state.selectedTrip!.price,
    );
    emit(
      state.copyWith(confirmedBooking: booking, step: BookingStep.confirmation),
    );
  }

  void resetBooking() {
    emit(const BookingState());
  }
}
