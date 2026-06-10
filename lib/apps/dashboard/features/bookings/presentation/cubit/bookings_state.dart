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
  final BookingStatus activeTab;

  const BookingsLoaded({
    required this.bookings,
    required this.filters,
    this.selectedIds = const {},
    this.openedBooking,
    this.activeTab = BookingStatus.underReview,
  });

  List<OperationBooking> get filteredBookings {
    final search = filters.search.trim().toLowerCase();
    return bookings.where((booking) {
      // Tab filter
      if (booking.status != activeTab) return false;

      final searchText = [
        booking.passengerName,
        booking.phone,
        booking.route,
        booking.seat,
        booking.paymentMethod.label,
        booking.id,
      ].join(' ').toLowerCase();
      final searchMatch = search.isEmpty || searchText.contains(search);
      final routeMatch =
          filters.route.trim().isEmpty ||
          booking.route.contains(filters.route.trim());
      final dateMatch =
          filters.date.trim().isEmpty ||
          booking.date.contains(filters.date.trim());
      final paymentMatch =
          filters.paymentMethod == null ||
          booking.paymentMethod == filters.paymentMethod;
      final priorityMatch =
          filters.priority == null || booking.priority == filters.priority;
      return searchMatch &&
          routeMatch &&
          dateMatch &&
          paymentMatch &&
          priorityMatch;
    }).toList();
  }

  int countByStatus(BookingStatus status) {
    return bookings.where((b) => b.status == status).length;
  }

  BookingsLoaded copyWith({
    List<OperationBooking>? bookings,
    BookingFilters? filters,
    Set<String>? selectedIds,
    OperationBooking? openedBooking,
    bool clearOpenedBooking = false,
    BookingStatus? activeTab,
  }) {
    return BookingsLoaded(
      bookings: bookings ?? this.bookings,
      filters: filters ?? this.filters,
      selectedIds: selectedIds ?? this.selectedIds,
      openedBooking: clearOpenedBooking
          ? null
          : openedBooking ?? this.openedBooking,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}
