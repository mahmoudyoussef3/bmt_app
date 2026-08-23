import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';

import '../../domain/entities/booking_lifecycle.dart';
import '../../domain/entities/operation_booking.dart';
import '../models/booking_filters.dart';
import '../models/booking_queue_tab.dart';
import '../models/booking_sort.dart';

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
  /// Rows per page on the board. The whole set used to render at once, which on
  /// a busy office meant hundreds of cards laid out to show the twelve the
  /// operator was actually working through.
  static const int pageSize = 12;

  final List<OperationBooking> bookings;
  final BookingFilters filters;
  final Set<String> selectedIds;
  final OperationBooking? openedBooking;
  final BookingQueueTab activeTab;
  final BookingSortField sortField;
  final bool sortAscending;
  final int page;

  /// True when the backing query returned a full page at
  /// [DashboardQueryCaps.bookings], so this queue is the newest slice of the
  /// office's history rather than all of it.
  ///
  /// Every tally on this state — the tab counts, `approvedRevenue`,
  /// `availableRoutes` — is computed over [bookings], so when this is true they
  /// describe the window and not the business. The board says so instead of
  /// presenting them as totals.
  bool get capReached => bookings.length >= DashboardQueryCaps.bookings;

  /// A failed action (approve, reject, reassign…). Surfaced as a snack bar over
  /// the still-intact workspace rather than as a full error screen: losing the
  /// list, filters and selection because one RPC failed is not recoverable work.
  final String? actionError;

  /// True while a review/reassign RPC is in flight, so the UI can disable
  /// action buttons instead of allowing a double submit.
  final bool isProcessing;

  /// True while a CSV export is in flight, kept apart from [isProcessing] so
  /// exporting the queue never disables the review actions and vice versa.
  final bool isExporting;

  /// The file name of the export the operator just finished, surfaced as a
  /// transient success snack bar the same way [actionError] surfaces a failure.
  final String? exportedFileName;

  BookingsLoaded({
    required this.bookings,
    required this.filters,
    this.selectedIds = const {},
    this.openedBooking,
    this.activeTab = BookingQueueTab.needsReview,
    this.sortField = BookingSortField.createdAt,
    this.sortAscending = false,
    this.page = 0,
    this.actionError,
    this.isProcessing = false,
    this.isExporting = false,
    this.exportedFileName,
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
      if (!activeTab.matches(booking)) return false;

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
      final paymentStatusMatch =
          filters.paymentStatus == null ||
          booking.paymentStatus == filters.paymentStatus;
      return searchMatch &&
          routeMatch &&
          dateMatch &&
          paymentMatch &&
          paymentStatusMatch;
    }).toList();
  }

  /// The filtered set in the operator's chosen order.
  late final List<OperationBooking> sortedBookings = _sort();

  List<OperationBooking> _sort() {
    final sorted = [...filteredBookings]
      ..sort((a, b) {
        final result = sortField.compare(a, b);
        return sortAscending ? result : -result;
      });
    return sorted;
  }

  int get resultCount => filteredBookings.length;

  int get pageCount {
    final pages = (resultCount / pageSize).ceil();
    return pages < 1 ? 1 : pages;
  }

  /// [page] can outlive the result set it was chosen for — approving the last
  /// row on page 4, or typing into search, can shrink the list under it. Reading
  /// the page through this clamp keeps the board on a real page instead of
  /// rendering an empty one.
  int get currentPage => page < 0
      ? 0
      : page > pageCount - 1
      ? pageCount - 1
      : page;

  late final List<OperationBooking> pageBookings = sortedBookings
      .skip(currentPage * pageSize)
      .take(pageSize)
      .toList();

  /// Rows on the current page that a bulk review can actually act on. Bulk
  /// approve/reject run the per-booking payment RPCs, which reject a booking
  /// whose payment is not awaiting a decision — *and* one whose booking is no
  /// longer `reserved` — so selecting one is a guaranteed failure, and the board
  /// never offers it.
  late final List<OperationBooking> selectablePageBookings = pageBookings
      .where((booking) => booking.canReviewPayment)
      .toList();

  bool get allPageSelected =>
      selectablePageBookings.isNotEmpty &&
      selectablePageBookings.every((b) => selectedIds.contains(b.id));

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

  /// How many bookings each tab would show, so the tab strip can carry its own
  /// count badge without the board re-filtering once per tab.
  int countForTab(BookingQueueTab tab) => switch (tab) {
    BookingQueueTab.needsReview => awaitingReviewCount,
    BookingQueueTab.all => bookings.length,
    _ => countByStatus(tab.status!),
  };

  late final int awaitingReviewCount = bookings
      .where((booking) => booking.awaitingReview)
      .length;

  /// Money the office has already accepted, which is the number an operator is
  /// asked for far more often than a raw count of approved rows.
  late final double approvedRevenue = bookings
      .where((booking) => booking.paymentStatus == PaymentStatus.approved)
      .fold<double>(0, (sum, booking) => sum + booking.paymentAmount);

  late final int settledOutCount =
      countByPaymentStatus(PaymentStatus.rejected) +
      countByStatus(BookingStatus.cancelled);

  /// Bookings created today (by wall-clock day), and the same for yesterday —
  /// the pair the "حجوزات اليوم" tile compares against. Scoped by
  /// [OperationBooking.createdAt] because that is the only timestamp the row
  /// actually carries; there is no separate "cancelled at" column, so
  /// [cancelledToday] below reads as *created and cancelled the same day*
  /// rather than *cancelled today*, and says so.
  List<OperationBooking> _createdOn(DateTime day) => bookings
      .where(
        (b) =>
            b.createdAt.year == day.year &&
            b.createdAt.month == day.month &&
            b.createdAt.day == day.day,
      )
      .toList();

  late final List<OperationBooking> _createdToday = _createdOn(DateTime.now());
  late final int bookingsCreatedToday = _createdToday.length;
  late final int bookingsCreatedYesterday = _createdOn(
    DateTime.now().subtract(const Duration(days: 1)),
  ).length;

  /// Value of the bookings created today, regardless of payment outcome —
  /// today's booking volume in money terms.
  late final double todayBookingValue = _createdToday.fold<double>(
    0,
    (sum, b) => sum + b.paymentAmount,
  );

  /// Bookings created *and* cancelled today. See the doc above for why this is
  /// not the same as "every booking cancelled today".
  late final List<OperationBooking> _cancelledToday = _createdToday
      .where((b) => b.status == BookingStatus.cancelled)
      .toList();

  late final int cancelledTodayCount = _cancelledToday.length;
  late final int cancelledTodayRefundedCount = _cancelledToday
      .where((b) => b.paymentStatus == PaymentStatus.refunded)
      .length;

  /// Distinct routes present in the loaded set, for the route filter. Picking
  /// from what exists beats typing a substring that may match nothing.
  late final List<String> availableRoutes =
      (bookings
          .map((booking) => booking.route.trim())
          .where((route) => route.isNotEmpty)
          .toSet()
          .toList()
        ..sort());

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
    BookingQueueTab? activeTab,
    BookingSortField? sortField,
    bool? sortAscending,
    int? page,
    String? actionError,
    bool clearActionError = false,
    bool? isProcessing,
    bool? isExporting,
    String? exportedFileName,
    bool clearExportedFileName = false,
  }) {
    return BookingsLoaded(
      bookings: bookings ?? this.bookings,
      filters: filters ?? this.filters,
      selectedIds: selectedIds ?? this.selectedIds,
      openedBooking: clearOpenedBooking
          ? null
          : openedBooking ?? this.openedBooking,
      activeTab: activeTab ?? this.activeTab,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      actionError: clearActionError ? null : actionError ?? this.actionError,
      isProcessing: isProcessing ?? this.isProcessing,
      isExporting: isExporting ?? this.isExporting,
      exportedFileName: clearExportedFileName
          ? null
          : exportedFileName ?? this.exportedFileName,
    );
  }
}
