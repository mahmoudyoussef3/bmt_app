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
    this.activeTab = BookingStatus.reserved,
  });

  List<OperationBooking> get filteredBookings {
    final search = filters.search.trim().toLowerCase();
    final route = filters.route.trim();
    final date = filters.date.trim();
    return bookings.where((booking) {
      if (booking.status != activeTab) return false;

      final searchText = [
        booking.passengerName,
        booking.phone,
        booking.route,
        booking.seat,
        booking.bookingNumber,
        booking.id,
      ].join(' ').toLowerCase();
      final searchMatch = search.isEmpty || searchText.contains(search);
      final routeMatch = route.isEmpty || booking.route.contains(route);
      final dateMatch = date.isEmpty || booking.date.contains(date);
      final paymentMatch =
          filters.paymentMethod == null ||
          booking.paymentMethod == filters.paymentMethod;
      return searchMatch && routeMatch && dateMatch && paymentMatch;
    }).toList();
  }

  int countByStatus(BookingStatus status) =>
      bookings.where((b) => b.status == status).length;

  int countByPaymentStatus(PaymentStatus status) =>
      bookings.where((b) => b.paymentStatus == status).length;

  /// Number of bookings the given client has ever made — a real cross-booking
  /// relationship derived from the loaded dataset (no extra query, no PII join).
  int bookingsForClient(String clientId) {
    if (clientId.isEmpty) return 0;
    return bookings.where((b) => b.clientId == clientId).length;
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
