import '../../domain/entities/operation_booking.dart';
import '../models/booking_filters.dart';

sealed class BookingsState {
  const BookingsState();
}

class BookingsLoading extends BookingsState {
  const BookingsLoading();
}

class BookingsError extends BookingsState {
  final String message;

  const BookingsError(this.message);
}

class BookingsLoaded extends BookingsState {
  final List<OperationBooking> bookings;
  final BookingFilters filters;
  final Set<String> selectedIds;
  final OperationBooking? openedBooking;

  const BookingsLoaded({
    required this.bookings,
    required this.filters,
    this.selectedIds = const {},
    this.openedBooking,
  });

  List<OperationBooking> get filteredBookings {
    final search = filters.search.trim().toLowerCase();
    return bookings.where((booking) {
      final searchText = [
        booking.passengerName,
        booking.phone,
        booking.route,
        booking.seat,
        booking.paymentMethod.label,
      ].join(' ').toLowerCase();
      final searchMatch = search.isEmpty || searchText.contains(search);
      final routeMatch =
          filters.route.trim().isEmpty ||
          booking.route.contains(filters.route.trim());
      final dateMatch =
          filters.date.trim().isEmpty ||
          booking.date.contains(filters.date.trim());
      final statusMatch =
          filters.status == null || booking.status == filters.status;
      final paymentMatch =
          filters.paymentMethod == null ||
          booking.paymentMethod == filters.paymentMethod;
      return searchMatch &&
          routeMatch &&
          dateMatch &&
          statusMatch &&
          paymentMatch;
    }).toList();
  }

  List<OperationBooking> bookingsByStatus(BookingStatus status) {
    return filteredBookings
        .where((booking) => booking.status == status)
        .toList();
  }

  BookingsLoaded copyWith({
    List<OperationBooking>? bookings,
    BookingFilters? filters,
    Set<String>? selectedIds,
    OperationBooking? openedBooking,
    bool clearOpenedBooking = false,
  }) {
    return BookingsLoaded(
      bookings: bookings ?? this.bookings,
      filters: filters ?? this.filters,
      selectedIds: selectedIds ?? this.selectedIds,
      openedBooking: clearOpenedBooking
          ? null
          : openedBooking ?? this.openedBooking,
    );
  }
}
