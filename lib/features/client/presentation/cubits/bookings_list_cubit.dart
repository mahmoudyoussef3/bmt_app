import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/shared/models/models.dart';
import 'package:bmt_app/shared/mock_data/mock_data.dart';

part 'bookings_list_state.dart';

class BookingsListCubit extends Cubit<BookingsListState> {
  BookingsListCubit() : super(const BookingsListState()) {
    loadBookings();
  }

  void loadBookings() {
    final bookings = MockData.getUserBookings(MockData.currentUser.id);
    emit(BookingsListState(bookings: bookings));
  }

  void cancelBooking(String bookingId) {
    final updatedBookings = state.bookings.map((booking) {
      if (booking.id == bookingId) {
        return booking; // In real app, would create cancelled booking
      }
      return booking;
    }).toList();
    emit(BookingsListState(bookings: updatedBookings));
  }
}
