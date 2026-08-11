import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/entities/captain_request.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart'
    show RevenueMetrics;
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/domain/entities/office_profile.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/entities/booking_payment_verification.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/domain/entities/reviews_summary.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/domain/entities/trip_review_entry.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/entities/complaint.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';

/// Everything the Home screen shows, assembled from other features' already-loaded
/// entities. Home owns no query of its own: every list here comes straight from a
/// sibling repository's use case, so a number shown here always matches what the
/// corresponding full module screen (Trips, Bookings, Fleet, …) shows for the same
/// office. Counts are computed on the raw lists rather than pre-aggregated, mirroring
/// how `BookingsLoaded` derives its own status tallies.
class DashboardHomeSummary {
  final List<OperationTrip> trips;
  final List<OperationBooking> bookings;
  final List<BookingPaymentVerification> paymentVerifications;
  final RevenueMetrics revenue;
  final FleetWorkspace fleet;
  final List<CaptainRequest> captainRequests;
  final List<TripReviewEntry> reviews;
  final OfficeProfile officeProfile;
  final List<SupportTicket> tickets;
  final List<UserSubscription> subscriptions;

  DashboardHomeSummary({
    required this.trips,
    required this.bookings,
    required this.paymentVerifications,
    required this.revenue,
    required this.fleet,
    required this.captainRequests,
    required this.reviews,
    required this.officeProfile,
    required this.tickets,
    required this.subscriptions,
  });

  late final List<OperationTrip> todayTrips = trips.where((trip) {
    final at = trip.scheduledAt;
    if (at == null) return false;
    final now = DateTime.now();
    return at.year == now.year && at.month == now.month && at.day == now.day;
  }).toList();

  int get todayTripsCount => todayTrips.length;

  /// Today's trips in the order they leave — the order the operator works
  /// through them, and the order the board at the station would show.
  late final List<OperationTrip> todayTripsByDeparture = List.of(todayTrips)
    ..sort((a, b) {
      final at = a.scheduledAt;
      final bt = b.scheduledAt;
      if (at == null || bt == null) return 0;
      return at.compareTo(bt);
    });

  late final Map<OperationTripStatus, int> _todayTripStatusCounts = _tally(
    todayTrips.map((trip) => trip.status),
  );

  int tripsCountByStatus(OperationTripStatus status) =>
      _todayTripStatusCounts[status] ?? 0;

  /// Total seat capacity vs. booked seats across today's trips — a real,
  /// derivable occupancy figure, not a fabricated percentage.
  double get todayOccupancyRate {
    if (todayTrips.isEmpty) return 0;
    final capacity = todayTrips.fold<int>(
      0,
      (sum, trip) => sum + trip.capacity,
    );
    if (capacity == 0) return 0;
    final booked = todayTrips.fold<int>(
      0,
      (sum, trip) => sum + trip.bookedSeats,
    );
    return booked / capacity;
  }

  /// Soonest-departure, highest-occupancy trips first — what an operator scanning
  /// the home page actually wants to see, not raw creation order.
  List<OperationTrip> upcomingTrips({int limit = 6}) {
    final upcoming =
        trips.where((trip) {
          final at = trip.scheduledAt;
          if (at == null) return false;
          return at.isAfter(
                DateTime.now().subtract(const Duration(hours: 1)),
              ) &&
              trip.status != OperationTripStatus.cancelled &&
              trip.status != OperationTripStatus.completed;
        }).toList()..sort((a, b) {
          final byTime = (a.scheduledAt ?? DateTime.now()).compareTo(
            b.scheduledAt ?? DateTime.now(),
          );
          if (byTime != 0) return byTime;
          return b.bookedSeats.compareTo(a.bookedSeats);
        });
    return upcoming.take(limit).toList();
  }

  late final Map<BookingStatus, int> _bookingStatusCounts = _tally(
    bookings.map((b) => b.status),
  );
  late final Map<PaymentStatus, int> _paymentStatusCounts = _tally(
    bookings.map((b) => b.paymentStatus),
  );

  int bookingCountByStatus(BookingStatus status) =>
      _bookingStatusCounts[status] ?? 0;

  int paymentCountByStatus(PaymentStatus status) =>
      _paymentStatusCounts[status] ?? 0;

  int get todayBookingsCount => bookings.where((b) {
    final at = DateTime.tryParse(b.date);
    if (at == null) return false;
    final now = DateTime.now();
    return at.year == now.year && at.month == now.month && at.day == now.day;
  }).length;

  /// The newest bookings, exactly as the Bookings module orders them
  /// (`created_at desc`, and that query is uncapped) — so this is genuinely
  /// "the last N that came in", not a sample.
  List<OperationBooking> recentBookings({int limit = 6}) {
    final sorted = List.of(bookings)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  /// Daily collected booking revenue over the last [days] days, oldest first,
  /// with quiet days present as zeros so the line keeps its true shape.
  ///
  /// Counts a booking only when its payment reached [PaymentStatus.approved],
  /// dated by `created_at` — the same two rules the Finance module's realised
  /// revenue uses (`_paidPaymentStatus` + `created_at` in
  /// `SupabaseFinanceDatasource`). Subscription revenue is deliberately *not*
  /// folded in: it is not in this list, so including it would mean guessing.
  /// Whatever labels this series must therefore say "الحجوزات", not "الإيرادات".
  List<DailyRevenuePoint> bookingRevenueSeries({int days = 7, DateTime? now}) {
    final today = _startOfDay(now ?? DateTime.now());
    final first = today.subtract(Duration(days: days - 1));

    final totals = <DateTime, double>{
      for (var i = 0; i < days; i++) first.add(Duration(days: i)): 0,
    };
    final counts = <DateTime, int>{for (final day in totals.keys) day: 0};

    for (final booking in bookings) {
      if (booking.paymentStatus != PaymentStatus.approved) continue;
      final day = _startOfDay(booking.createdAt);
      if (day.isBefore(first) || day.isAfter(today)) continue;
      totals[day] = (totals[day] ?? 0) + booking.paymentAmount;
      counts[day] = (counts[day] ?? 0) + 1;
    }

    return [
      for (final day in totals.keys)
        DailyRevenuePoint(
          day: day,
          amount: totals[day] ?? 0,
          bookings: counts[day] ?? 0,
        ),
    ];
  }

  /// How full each route ran, best first, over the trips in the last
  /// [windowDays] days plus everything still ahead.
  ///
  /// Cancelled trips are excluded (a cancelled bus was never going to fill),
  /// as are routes with no seats on offer — dividing by a zero capacity is how
  /// a "0% route" that never existed ends up on the board.
  List<RouteOccupancy> topRoutes({
    int limit = 5,
    int windowDays = 30,
    DateTime? now,
  }) {
    final from = _startOfDay(
      now ?? DateTime.now(),
    ).subtract(Duration(days: windowDays));

    final booked = <String, int>{};
    final capacity = <String, int>{};
    final tripCount = <String, int>{};

    for (final trip in trips) {
      if (trip.status == OperationTripStatus.cancelled) continue;
      final at = trip.scheduledAt;
      if (at == null || at.isBefore(from)) continue;
      final route = trip.route.trim();
      if (route.isEmpty || trip.capacity == 0) continue;
      booked[route] = (booked[route] ?? 0) + trip.bookedSeats;
      capacity[route] = (capacity[route] ?? 0) + trip.capacity;
      tripCount[route] = (tripCount[route] ?? 0) + 1;
    }

    final rows =
        [
          for (final route in capacity.keys)
            RouteOccupancy(
              route: route,
              bookedSeats: booked[route] ?? 0,
              capacity: capacity[route] ?? 0,
              trips: tripCount[route] ?? 0,
            ),
        ]..sort((a, b) {
          final byRate = b.occupancyRate.compareTo(a.occupancyRate);
          if (byRate != 0) return byRate;
          return b.bookedSeats.compareTo(a.bookedSeats);
        });

    return rows.take(limit).toList();
  }

  late final List<BookingPaymentVerification> pendingPaymentReviews =
      paymentVerifications
          .where((p) => p.status == BookingVerificationStatus.pending)
          .toList();

  int get pendingPaymentReviewsCount => pendingPaymentReviews.length;

  FleetSummary get fleetSummary => fleet.summary;

  late final List<CaptainRequest> pendingCaptainRequests = captainRequests
      .where((r) => r.isPending)
      .toList();

  int get pendingCaptainRequestsCount => pendingCaptainRequests.length;

  ReviewsSummary get reviewsSummary => ReviewsSummary.from(reviews);

  /// Open complaints, most urgent and most recently updated first.
  List<SupportTicket> openComplaints({int limit = 5}) {
    final open =
        tickets
            .where(
              (t) =>
                  t.status != TicketStatus.resolved &&
                  t.status != TicketStatus.closed &&
                  t.status != TicketStatus.rejected,
            )
            .toList()
          ..sort((a, b) {
            final byPriority = b.priority.index.compareTo(a.priority.index);
            if (byPriority != 0) return byPriority;
            return b.updatedAt.compareTo(a.updatedAt);
          });
    return open.take(limit).toList();
  }

  /// Subscriptions worth an operator's attention: awaiting payment first,
  /// then active ones running out soonest.
  List<UserSubscription> subscriptionsNeedingFollowUp({int limit = 5}) {
    final relevant =
        subscriptions
            .where(
              (s) =>
                  s.status == SubscriptionStatus.pendingPayment ||
                  s.status == SubscriptionStatus.active,
            )
            .toList()
          ..sort((a, b) {
            if (a.status != b.status) {
              return a.status == SubscriptionStatus.pendingPayment ? -1 : 1;
            }
            return a.remainingDays.compareTo(b.remainingDays);
          });
    return relevant.take(limit).toList();
  }

  /// Trips still open or scheduled that nobody is driving.
  ///
  /// The planner requires a driver today, so a trip without one is either
  /// older than that rule or lost its driver afterwards — either way it is a
  /// bus that will not leave, and nothing else on the console says so.
  late final List<OperationTrip> tripsWithoutCaptain = trips.where((trip) {
    if (trip.status == OperationTripStatus.cancelled ||
        trip.status == OperationTripStatus.completed) {
      return false;
    }
    final at = trip.scheduledAt;
    if (at == null || at.isBefore(_startOfDay(DateTime.now()))) return false;
    return trip.driver.trim().isEmpty;
  }).toList();

  /// Trips still advertised as bookable after their departure day — invisible
  /// to passengers, still counted as open inventory here. Nothing retires
  /// them by design; an operator has to close or cancel each one.
  late final List<OperationTrip> staleTrips = trips
      .where((trip) => trip.isStaleBooking())
      .toList();

  /// Open complaints a passenger is actively waiting on, at the two priorities
  /// that mean "today", not "this week".
  late final List<SupportTicket> urgentComplaints = tickets
      .where(
        (t) =>
            t.status != TicketStatus.resolved &&
            t.status != TicketStatus.closed &&
            t.status != TicketStatus.rejected &&
            (t.priority == TicketPriority.urgent ||
                t.priority == TicketPriority.high),
      )
      .toList();

  late final List<UserSubscription> subscriptionsAwaitingPayment = subscriptions
      .where((s) => s.status == SubscriptionStatus.pendingPayment)
      .toList();

  /// Everything waiting on the operator right now, most urgent first.
  ///
  /// Every entry is a real queue with a real count derived from the lists
  /// above — there is no "you might want to look at…" item, and an empty
  /// result means the console genuinely has nothing to escalate.
  late final List<HomeAttentionItem> attentionItems = () {
    final items = <HomeAttentionItem>[
      HomeAttentionItem(
        kind: HomeAttentionKind.tripsWithoutCaptain,
        count: tripsWithoutCaptain.length,
      ),
      HomeAttentionItem(
        kind: HomeAttentionKind.staleTrips,
        count: staleTrips.length,
      ),
      HomeAttentionItem(
        kind: HomeAttentionKind.paymentsAwaitingReview,
        count: pendingPaymentReviewsCount,
      ),
      HomeAttentionItem(
        kind: HomeAttentionKind.urgentComplaints,
        count: urgentComplaints.length,
      ),
      HomeAttentionItem(
        kind: HomeAttentionKind.captainRequests,
        count: pendingCaptainRequestsCount,
      ),
      HomeAttentionItem(
        kind: HomeAttentionKind.expiringDocuments,
        count: fleetSummary.documentsNeedFollowUpCount,
      ),
      HomeAttentionItem(
        kind: HomeAttentionKind.subscriptionsAwaitingPayment,
        count: subscriptionsAwaitingPayment.length,
      ),
    ].where((item) => item.count > 0).toList();

    items.sort((a, b) {
      final bySeverity = b.kind.severity.index.compareTo(a.kind.severity.index);
      if (bySeverity != 0) return bySeverity;
      return b.count.compareTo(a.count);
    });
    return items;
  }();

  Map<T, int> _tally<T>(Iterable<T> values) {
    final counts = <T, int>{};
    for (final value in values) {
      counts.update(value, (v) => v + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  static DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

/// One day on the home screen's revenue line.
class DailyRevenuePoint {
  final DateTime day;

  /// Collected booking revenue on this day.
  final double amount;

  /// How many approved bookings made it up — the context that keeps a single
  /// expensive booking from reading as a busy day.
  final int bookings;

  const DailyRevenuePoint({
    required this.day,
    required this.amount,
    required this.bookings,
  });
}

/// How full one route ran over the window the home screen ranks.
class RouteOccupancy {
  final String route;
  final int bookedSeats;
  final int capacity;
  final int trips;

  const RouteOccupancy({
    required this.route,
    required this.bookedSeats,
    required this.capacity,
    required this.trips,
  });

  double get occupancyRate => capacity == 0 ? 0 : bookedSeats / capacity;
}

/// How loudly an attention item should speak.
///
/// Ordered weakest → strongest so `index` can be compared directly when
/// sorting the queue.
enum HomeAttentionSeverity { info, warning, urgent }

/// The kinds of work that can be waiting on an operator.
///
/// The severity lives on the kind, not on the instance: "a trip with no
/// captain" is always urgent and "a new captain application" never is, so
/// letting each call site decide is how the same queue ends up amber on one
/// screen and red on another.
enum HomeAttentionKind {
  tripsWithoutCaptain(HomeAttentionSeverity.urgent),
  staleTrips(HomeAttentionSeverity.urgent),
  paymentsAwaitingReview(HomeAttentionSeverity.warning),
  urgentComplaints(HomeAttentionSeverity.warning),
  expiringDocuments(HomeAttentionSeverity.warning),
  captainRequests(HomeAttentionSeverity.info),
  subscriptionsAwaitingPayment(HomeAttentionSeverity.info);

  final HomeAttentionSeverity severity;

  const HomeAttentionKind(this.severity);
}

/// A queue with something in it. Never constructed with a zero [count] — an
/// empty queue is simply absent from [DashboardHomeSummary.attentionItems],
/// because a warning box that says "0 problems" is still a warning box.
class HomeAttentionItem {
  final HomeAttentionKind kind;
  final int count;

  const HomeAttentionItem({required this.kind, required this.count});
}
