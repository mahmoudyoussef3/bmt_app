import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/entities/captain_request.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/entities/booking_payment_verification.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/entities/complaint.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';

import 'dashboard_home_test_fixtures.dart';

void main() {
  group('DashboardHomeSummary — trips', () {
    test('todayTrips only includes trips scheduled for today', () {
      final now = DateTime.now();
      final summary = buildSummary(
        trips: [
          buildTrip(id: 't1', at: now, capacity: 10, bookedSeats: 4),
          buildTrip(
            id: 't2',
            at: now.subtract(const Duration(days: 1)),
            capacity: 10,
          ),
          buildTrip(id: 't3', at: now.add(const Duration(days: 2)), capacity: 10),
        ],
      );

      expect(summary.todayTripsCount, 1);
      expect(summary.todayTrips.single.id, 't1');
    });

    test('tripsCountByStatus tallies only today\'s trips by status', () {
      final now = DateTime.now();
      final summary = buildSummary(
        trips: [
          buildTrip(id: 't1', at: now, status: OperationTripStatus.completed),
          buildTrip(id: 't2', at: now, status: OperationTripStatus.completed),
          buildTrip(id: 't3', at: now, status: OperationTripStatus.cancelled),
          // Not today — must not be counted.
          buildTrip(
            id: 't4',
            at: now.add(const Duration(days: 1)),
            status: OperationTripStatus.completed,
          ),
        ],
      );

      expect(summary.tripsCountByStatus(OperationTripStatus.completed), 2);
      expect(summary.tripsCountByStatus(OperationTripStatus.cancelled), 1);
      expect(summary.tripsCountByStatus(OperationTripStatus.scheduled), 0);
    });

    test('todayOccupancyRate is booked seats over total capacity today', () {
      final now = DateTime.now();
      final summary = buildSummary(
        trips: [
          buildTrip(id: 't1', at: now, capacity: 10, bookedSeats: 5),
          buildTrip(id: 't2', at: now, capacity: 10, bookedSeats: 10),
        ],
      );

      expect(summary.todayOccupancyRate, closeTo(0.75, 0.0001));
    });

    test('todayOccupancyRate is zero with no trips today, never divides by zero', () {
      final summary = buildSummary(trips: const []);
      expect(summary.todayOccupancyRate, 0);
    });

    test('upcomingTrips excludes cancelled/completed and past trips, sorted by time', () {
      final now = DateTime.now();
      final soon = buildTrip(
        id: 'soon',
        at: now.add(const Duration(hours: 1)),
        capacity: 10,
        bookedSeats: 2,
      );
      final later = buildTrip(
        id: 'later',
        at: now.add(const Duration(hours: 5)),
        capacity: 10,
        bookedSeats: 9,
      );
      final cancelled = buildTrip(
        id: 'cancelled',
        at: now.add(const Duration(hours: 2)),
        status: OperationTripStatus.cancelled,
      );
      final past = buildTrip(
        id: 'past',
        at: now.subtract(const Duration(days: 1)),
      );

      final summary = buildSummary(trips: [later, cancelled, past, soon]);
      final upcoming = summary.upcomingTrips();

      expect(upcoming.map((t) => t.id), ['soon', 'later']);
    });
  });

  group('DashboardHomeSummary — bookings & payments', () {
    test('bookingCountByStatus and paymentCountByStatus tally the full set', () {
      final summary = buildSummary(
        bookings: [
          buildBooking(id: 'b1', status: BookingStatus.confirmed),
          buildBooking(id: 'b2', status: BookingStatus.confirmed),
          buildBooking(id: 'b3', status: BookingStatus.cancelled),
          buildBooking(
            id: 'b4',
            status: BookingStatus.reserved,
            paymentStatus: PaymentStatus.approved,
          ),
        ],
      );

      expect(summary.bookingCountByStatus(BookingStatus.confirmed), 2);
      expect(summary.bookingCountByStatus(BookingStatus.cancelled), 1);
      expect(summary.paymentCountByStatus(PaymentStatus.approved), 1);
      expect(summary.paymentCountByStatus(PaymentStatus.pending), 3);
    });

    test('pendingPaymentReviewsCount counts only pending verifications', () {
      final summary = buildSummary(
        paymentVerifications: [
          buildPaymentVerification(id: 'p1'),
          buildPaymentVerification(
            id: 'p2',
            status: BookingVerificationStatus.approved,
          ),
          buildPaymentVerification(id: 'p3'),
        ],
      );

      expect(summary.pendingPaymentReviewsCount, 2);
    });
  });

  group('DashboardHomeSummary — captains & fleet', () {
    test('pendingCaptainRequestsCount counts only pending requests', () {
      final summary = buildSummary(
        captainRequests: [
          buildCaptainRequest(id: 'c1'),
          buildCaptainRequest(
            id: 'c2',
            status: CaptainRequestStatus.approved,
          ),
          buildCaptainRequest(id: 'c3'),
        ],
      );

      expect(summary.pendingCaptainRequestsCount, 2);
    });

    test('fleetSummary passes through FleetWorkspace.summary unchanged', () {
      final summary = buildSummary();
      expect(summary.fleetSummary.driversCount, 0);
      expect(summary.fleetSummary.vehiclesCount, 0);
    });
  });

  group('DashboardHomeSummary — complaints & subscriptions', () {
    test('openComplaints excludes resolved/closed/rejected, urgent first', () {
      final summary = buildSummary(
        tickets: [
          buildTicket(id: 't1', priority: TicketPriority.low),
          buildTicket(id: 't2', priority: TicketPriority.urgent),
          buildTicket(id: 't3', status: TicketStatus.resolved),
          buildTicket(id: 't4', status: TicketStatus.closed),
        ],
      );

      final open = summary.openComplaints();
      expect(open.map((t) => t.id), ['t2', 't1']);
    });

    test('subscriptionsNeedingFollowUp puts pending-payment first, then soonest to expire', () {
      final summary = buildSummary(
        subscriptions: [
          buildSubscription(
            id: 's1',
            endDate: DateTime.now().add(const Duration(days: 20)),
          ),
          buildSubscription(
            id: 's2',
            status: SubscriptionStatus.pendingPayment,
          ),
          buildSubscription(
            id: 's3',
            endDate: DateTime.now().add(const Duration(days: 2)),
          ),
          buildSubscription(id: 's4', status: SubscriptionStatus.cancelled),
        ],
      );

      final followUp = summary.subscriptionsNeedingFollowUp();
      expect(followUp.map((s) => s.id), ['s2', 's3', 's1']);
    });
  });
}
