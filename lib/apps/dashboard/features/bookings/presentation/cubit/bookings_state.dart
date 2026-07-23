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

  /// A failed action (approve, reject, reassign…). Surfaced as a snack bar over
  /// the still-intact workspace rather than as a full error screen: losing the
  /// list, filters and selection because one RPC failed is not recoverable work.
  final String? actionError;

  /// True while a review/reassign RPC is in flight, so the UI can disable
  /// action buttons instead of allowing a double submit.
  final bool isProcessing;

  BookingsLoaded({
    required this.bookings,
    required this.filters,
    this.selectedIds = const {},
    this.openedBooking,
    this.activeTab = BookingStatus.reserved,
    this.actionError,
    this.isProcessing = false,
  });

  /// Computed once per state instance — the board reads this several times per
  /// build (list, counters, bulk bar), and re-filtering the whole set each time
  /// showed up as avoidable work on large booking sets.
  late final List<OperationBooking> filteredBookings = _filter();

  List<OperationBooking> _filter() {
    final search = filters.search.trim().toLowerCase();
    final route = filters.route.trim();
    final date = filters.date.trim();
    return bookings.where((booking) {
      if (booking.status != activeTab) return false;

      final searchMatch =
          search.isEmpty ||
          [
            booking.passengerName,
            booking.phone,
            booking.route,
            booking.seat,
            booking.bookingNumber,
            booking.id,
          ].join(' ').toLowerCase().contains(search);
      final routeMatch = route.isEmpty || booking.route.contains(route);
      final dateMatch = date.isEmpty || booking.date.contains(date);
      final paymentMatch =
          filters.paymentMethod == null ||
          booking.paymentMethod == filters.paymentMethod;
      return searchMatch && routeMatch && dateMatch && paymentMatch;
    }).toList();
  }

  /// Status/payment tallies for the whole set, built in a single pass instead of
  /// one full scan per counter.
  late final Map<BookingStatus, int> _statusCounts = _tally((b) => b.status);
  late final Map<PaymentStatus, int> _paymentCounts = _tally(
    (b) => b.paymentStatus,
  );

  Map<T, int> _tally<T>(T Function(OperationBooking) key) {
    final counts = <T, int>{};
    for (final booking in bookings) {
      counts.update(key(booking), (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  int countByStatus(BookingStatus status) => _statusCounts[status] ?? 0;

  int countByPaymentStatus(PaymentStatus status) => _paymentCounts[status] ?? 0;

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
    String? actionError,
    bool clearActionError = false,
    bool? isProcessing,
  }) {
    return BookingsLoaded(
      bookings: bookings ?? this.bookings,
      filters: filters ?? this.filters,
      selectedIds: selectedIds ?? this.selectedIds,
      openedBooking: clearOpenedBooking
          ? null
          : openedBooking ?? this.openedBooking,
      activeTab: activeTab ?? this.activeTab,
      actionError: clearActionError ? null : actionError ?? this.actionError,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
