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

  // ---- Trips -------------------------------------------------------------

  late final List<OperationTrip> todayTrips = trips.where((trip) {
    final at = trip.scheduledAt;
    if (at == null) return false;
    final now = DateTime.now();
    return at.year == now.year && at.month == now.month && at.day == now.day;
  }).toList();

  int get todayTripsCount => todayTrips.length;

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

  // ---- Bookings ------------------------------------------------------------

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

  // ---- Payments needing review ---------------------------------------------

  late final List<BookingPaymentVerification> pendingPaymentReviews =
      paymentVerifications
          .where((p) => p.status == BookingVerificationStatus.pending)
          .toList();

  int get pendingPaymentReviewsCount => pendingPaymentReviews.length;

  // ---- Fleet -----------------------------------------------------------

  FleetSummary get fleetSummary => fleet.summary;

  // ---- Captains ----------------------------------------------------------

  late final List<CaptainRequest> pendingCaptainRequests = captainRequests
      .where((r) => r.isPending)
      .toList();

  int get pendingCaptainRequestsCount => pendingCaptainRequests.length;

  // ---- Reviews -------------------------------------------------------------

  ReviewsSummary get reviewsSummary => ReviewsSummary.from(reviews);

  // ---- Tickets / complaints -------------------------------------------------

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

  // ---- Subscriptions ---------------------------------------------------

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

  Map<T, int> _tally<T>(Iterable<T> values) {
    final counts = <T, int>{};
    for (final value in values) {
      counts.update(value, (v) => v + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}
