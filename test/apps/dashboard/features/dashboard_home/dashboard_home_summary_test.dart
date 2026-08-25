import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/entities/captain_request.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/domain/entities/dashboard_home_summary.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart'
    show RevenueMetrics;
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
          buildTrip(
            id: 't3',
            at: now.add(const Duration(days: 2)),
            capacity: 10,
          ),
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

    test(
      'todayOccupancyRate is zero with no trips today, never divides by zero',
      () {
        final summary = buildSummary(trips: const []);
        expect(summary.todayOccupancyRate, 0);
      },
    );

    test(
      'upcomingTrips excludes cancelled/completed and past trips, sorted by time',
      () {
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
      },
    );
  });

  group('DashboardHomeSummary — bookings & payments', () {
    test(
      'bookingCountByStatus and paymentCountByStatus tally the full set',
      () {
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
      },
    );

    test('pendingPaymentReviewsCount counts only submitted receipts', () {
      // Derived from the bookings feed since مراجعة المدفوعات was folded into
      // الحجوزات. `underReview` is excluded on purpose: that booking is waiting
      // on the passenger to re-upload, not on the office to decide — the same
      // line the separate queue drew.
      final summary = buildSummary(
        bookings: [
          buildBooking(id: 'p1', paymentStatus: PaymentStatus.submitted),
          buildBooking(id: 'p2', paymentStatus: PaymentStatus.approved),
          buildBooking(id: 'p3', paymentStatus: PaymentStatus.submitted),
          buildBooking(id: 'p4', paymentStatus: PaymentStatus.underReview),
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
          buildCaptainRequest(id: 'c2', status: CaptainRequestStatus.approved),
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

    test(
      'urgentComplaints keeps only open tickets at the top two priorities',
      () {
        final summary = buildSummary(
          tickets: [
            buildTicket(id: 't1', priority: TicketPriority.urgent),
            buildTicket(id: 't2', priority: TicketPriority.high),
            buildTicket(id: 't3', priority: TicketPriority.low),
            buildTicket(
              id: 't4',
              priority: TicketPriority.urgent,
              status: TicketStatus.resolved,
            ),
          ],
        );

        expect(summary.urgentComplaints.map((t) => t.id), ['t1', 't2']);
      },
    );

    test(
      'subscriptionsNeedingFollowUp puts pending-payment first, then soonest to expire',
      () {
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
      },
    );
  });

  group('DashboardHomeSummary — home screen sections', () {
    test('todayTripsByDeparture orders today only, earliest first', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final summary = buildSummary(
        trips: [
          buildTrip(id: 'noon', at: today.add(const Duration(hours: 12))),
          buildTrip(id: 'dawn', at: today.add(const Duration(hours: 6))),
          buildTrip(id: 'evening', at: today.add(const Duration(hours: 19))),
          buildTrip(id: 'tomorrow', at: today.add(const Duration(days: 1))),
        ],
      );

      expect(summary.todayTripsByDeparture.map((t) => t.id), [
        'dawn',
        'noon',
        'evening',
      ]);
    });

    test('recentBookings returns the newest first, capped at the limit', () {
      final now = DateTime.now();
      final summary = buildSummary(
        bookings: [
          buildBooking(id: 'old', date: now.subtract(const Duration(days: 3))),
          buildBooking(id: 'newest', date: now),
          buildBooking(id: 'mid', date: now.subtract(const Duration(days: 1))),
        ],
      );

      expect(summary.recentBookings(limit: 2).map((b) => b.id), [
        'newest',
        'mid',
      ]);
    });

    group('bookingRevenueSeries', () {
      test('counts approved payments only, on the day they were booked', () {
        final now = DateTime(2026, 8, 2, 13);
        final summary = buildSummary(
          bookings: [
            buildBooking(
              id: 'paid-today',
              date: now,
              amount: 250,
              paymentStatus: PaymentStatus.approved,
            ),
            buildBooking(
              id: 'paid-yesterday',
              date: now.subtract(const Duration(days: 1)),
              amount: 100,
              paymentStatus: PaymentStatus.approved,
            ),
            // Money that never arrived, or came back — neither is revenue.
            buildBooking(
              id: 'pending',
              date: now,
              amount: 999,
              paymentStatus: PaymentStatus.pending,
            ),
            buildBooking(
              id: 'refunded',
              date: now,
              amount: 999,
              paymentStatus: PaymentStatus.refunded,
            ),
          ],
        );

        final series = summary.bookingRevenueSeries(days: 3, now: now);

        expect(series, hasLength(3));
        expect(series.first.day, DateTime(2026, 7, 31));
        expect(series.last.day, DateTime(2026, 8, 2));
        expect(series.map((p) => p.amount), [0, 100, 250]);
        expect(series.last.bookings, 1);
      });

      test('keeps quiet days as zeros so the line keeps its shape', () {
        final now = DateTime(2026, 8, 2);
        final summary = buildSummary(bookings: const []);

        final series = summary.bookingRevenueSeries(days: 7, now: now);

        expect(series, hasLength(7));
        expect(series.every((p) => p.amount == 0), isTrue);
      });

      test('ignores bookings older than the window', () {
        final now = DateTime(2026, 8, 2);
        final summary = buildSummary(
          bookings: [
            buildBooking(
              id: 'ancient',
              date: now.subtract(const Duration(days: 40)),
              amount: 500,
              paymentStatus: PaymentStatus.approved,
            ),
          ],
        );

        final series = summary.bookingRevenueSeries(days: 7, now: now);
        expect(series.fold<double>(0, (sum, p) => sum + p.amount), 0);
      });
    });

    group('topRoutes', () {
      test('ranks by occupancy across a route\'s trips', () {
        final now = DateTime.now();
        final summary = buildSummary(
          trips: [
            buildTrip(
              id: 'a1',
              route: 'بنها - القاهرة',
              at: now,
              capacity: 10,
              bookedSeats: 9,
            ),
            buildTrip(
              id: 'a2',
              route: 'بنها - القاهرة',
              at: now.subtract(const Duration(days: 1)),
              capacity: 10,
              bookedSeats: 7,
            ),
            buildTrip(
              id: 'b1',
              route: 'طنطا - القاهرة',
              at: now,
              capacity: 10,
              bookedSeats: 3,
            ),
          ],
        );

        final routes = summary.topRoutes();

        expect(routes.map((r) => r.route), [
          'بنها - القاهرة',
          'طنطا - القاهرة',
        ]);
        expect(routes.first.occupancyRate, closeTo(0.8, 0.0001));
        expect(routes.first.trips, 2);
        expect(routes.last.occupancyRate, closeTo(0.3, 0.0001));
      });

      test('excludes cancelled trips and anything outside the window', () {
        final now = DateTime.now();
        final summary = buildSummary(
          trips: [
            buildTrip(
              id: 'cancelled',
              route: 'ملغاة',
              at: now,
              capacity: 10,
              bookedSeats: 10,
              status: OperationTripStatus.cancelled,
            ),
            buildTrip(
              id: 'ancient',
              route: 'قديمة',
              at: now.subtract(const Duration(days: 60)),
              capacity: 10,
              bookedSeats: 10,
            ),
            buildTrip(
              id: 'live',
              route: 'حالية',
              at: now,
              capacity: 10,
              bookedSeats: 5,
            ),
          ],
        );

        expect(summary.topRoutes().map((r) => r.route), ['حالية']);
      });
    });

    group('attentionItems', () {
      test('is empty when nothing needs a decision', () {
        expect(buildSummary().attentionItems, isEmpty);
      });

      test('raises trips with no captain, urgent first, with real counts', () {
        final now = DateTime.now();
        final summary = buildSummary(
          trips: [
            buildTrip(
              id: 'no-driver',
              at: now.add(const Duration(hours: 3)),
              driver: '',
            ),
            buildTrip(id: 'staffed', at: now.add(const Duration(hours: 4))),
          ],
          captainRequests: [buildCaptainRequest(id: 'c1')],
        );

        final kinds = summary.attentionItems.map((i) => i.kind).toList();
        expect(kinds.first, HomeAttentionKind.tripsWithoutCaptain);
        expect(kinds, contains(HomeAttentionKind.captainRequests));
        expect(
          summary.attentionItems
              .firstWhere(
                (i) => i.kind == HomeAttentionKind.tripsWithoutCaptain,
              )
              .count,
          1,
        );
      });

      test('a completed trip with no captain is history, not a problem', () {
        final summary = buildSummary(
          trips: [
            buildTrip(
              id: 'done',
              at: DateTime.now(),
              driver: '',
              status: OperationTripStatus.completed,
            ),
          ],
        );

        expect(summary.tripsWithoutCaptain, isEmpty);
        expect(summary.attentionItems, isEmpty);
      });

      test('flags trips still open after their departure day', () {
        final summary = buildSummary(
          trips: [
            buildTrip(
              id: 'stale',
              at: DateTime.now().subtract(const Duration(days: 2)),
              status: OperationTripStatus.openForBooking,
            ),
          ],
        );

        expect(
          summary.attentionItems.map((i) => i.kind),
          contains(HomeAttentionKind.staleTrips),
        );
      });

      test('sorts urgent above warning above info', () {
        final summary = buildSummary(
          trips: [
            buildTrip(
              id: 'no-driver',
              at: DateTime.now().add(const Duration(hours: 2)),
              driver: '',
            ),
          ],
          bookings: [
            buildBooking(id: 'p1', paymentStatus: PaymentStatus.submitted),
          ],
          captainRequests: [buildCaptainRequest(id: 'c1')],
        );

        expect(summary.attentionItems.map((i) => i.kind.severity), [
          HomeAttentionSeverity.urgent,
          HomeAttentionSeverity.warning,
          HomeAttentionSeverity.info,
        ]);
      });
    });
  });

  // The KPI strip draws a headline number and, right underneath it, the shape
  // of the last week. Those two are only trustworthy together if they are
  // counted the same way, and the failure mode is silent — a sparkline whose
  // last point is one off the number above it looks fine and is wrong. Each
  // series is therefore pinned to the tile it sits under.
  group('DashboardHomeSummary — weekly series & movement', () {
    final now = DateTime(2026, 8, 25, 10);

    test('trip counts end on today and agree with todayTripsCount', () {
      final summary = buildSummary(
        trips: [
          buildTrip(id: 'a', at: now),
          buildTrip(id: 'b', at: now),
          buildTrip(
            id: 'cancelled-today',
            at: now,
            status: OperationTripStatus.cancelled,
          ),
          buildTrip(id: 'y1', at: now.subtract(const Duration(days: 1))),
          buildTrip(id: 'old', at: now.subtract(const Duration(days: 30))),
        ],
      );

      final series = summary.dailyTripCounts(days: 7, now: now);
      expect(series, hasLength(7));
      // A cancelled trip still counts, because todayTrips counts it too.
      expect(series.last, 3);
      expect(series[series.length - 2], 1);
      // Outside the window, so it never reaches the line.
      expect(series.reduce((a, b) => a + b), 4);
    });

    test('booking counts are dated by travel day, like todayBookingsCount', () {
      // Taken today for a trip tomorrow: it belongs to tomorrow's load, and
      // both the tile and the series have to agree on that.
      final summary = buildSummary(
        bookings: [
          buildBooking(id: 'today', date: now),
          buildBooking(
            id: 'yesterday',
            date: now.subtract(const Duration(days: 1)),
          ),
          buildBooking(
            id: 'yesterday-2',
            date: now.subtract(const Duration(days: 1)),
          ),
        ],
      );

      final series = summary.dailyBookingCounts(days: 7, now: now);
      expect(series.last, 1);
      expect(series[series.length - 2], 2);
    });

    test('occupancy per day is booked over offered, zero when nothing ran', () {
      final summary = buildSummary(
        trips: [
          buildTrip(id: 't', at: now, capacity: 10, bookedSeats: 5),
          buildTrip(id: 'u', at: now, capacity: 10, bookedSeats: 3),
        ],
      );

      final series = summary.dailyOccupancyRates(days: 7, now: now);
      expect(series.last, closeTo(0.4, 0.0001));
      expect(series.first, 0);
    });

    test('the delta is today against yesterday, and flat means flat', () {
      final summary = buildSummary(
        trips: [
          buildTrip(id: 'a', at: DateTime.now()),
          buildTrip(id: 'b', at: DateTime.now()),
          buildTrip(
            id: 'y',
            at: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      );

      expect(summary.tripsDelta.change, 1);
      expect(summary.tripsDelta.isUp, isTrue);
      expect(buildSummary().tripsDelta.isFlat, isTrue);
    });

    test('revenue compares against the week average, and not against zero', () {
      final quiet = buildSummary();
      expect(quiet.revenueAgainstWeeklyAverage, isNull);

      final busy = buildSummary(
        revenue: const RevenueMetrics(
          todayRevenue: 200,
          weeklyRevenue: 700,
          monthlyRevenue: 3000,
          activeSubscriptions: 0,
          totalBookingsRevenue: 3000,
        ),
      );
      final delta = busy.revenueAgainstWeeklyAverage!;
      expect(delta.previous, 100);
      expect(delta.percentChange, closeTo(100, 0.0001));
    });
  });

  group('DashboardHomeSummary — today at a glance', () {
    // These read `todayTrips`, which filters against the real wall clock, so
    // the fixtures have to be built on whatever day the suite runs. A literal
    // date here passes on the day it is written and silently stops exercising
    // anything the next morning, when every trip falls outside "today".
    final today = DateTime.now();
    DateTime at(int hour) => DateTime(today.year, today.month, today.day, hour);
    final now = at(9);

    test('nextDeparture skips what has left, been cancelled, or finished', () {
      final summary = buildSummary(
        trips: [
          buildTrip(id: 'gone', at: at(7)),
          buildTrip(
            id: 'cancelled',
            at: at(10),
            status: OperationTripStatus.cancelled,
          ),
          buildTrip(id: 'next', at: at(11)),
          buildTrip(id: 'later', at: at(13)),
        ],
      );

      expect(summary.nextDeparture(now: now)?.id, 'next');
    });

    test('nextDeparture is null once the board is done', () {
      final summary = buildSummary(
        trips: [buildTrip(id: 'gone', at: at(7))],
      );

      expect(summary.nextDeparture(now: now), isNull);
    });

    test('tripsRunningNow counts only buses boarding or under way', () {
      final summary = buildSummary(
        trips: [
          buildTrip(
            id: 'boarding',
            at: DateTime.now(),
            status: OperationTripStatus.boarding,
          ),
          buildTrip(
            id: 'moving',
            at: DateTime.now(),
            status: OperationTripStatus.inProgress,
          ),
          buildTrip(
            id: 'scheduled',
            at: DateTime.now(),
            status: OperationTripStatus.scheduled,
          ),
        ],
      );

      expect(summary.tripsRunningNow, hasLength(2));
    });

    test('seats on sale exclude trips that have already left', () {
      final summary = buildSummary(
        trips: [
          buildTrip(id: 'gone', at: at(7), capacity: 10, bookedSeats: 2),
          buildTrip(id: 'ahead', at: at(12), capacity: 10, bookedSeats: 4),
        ],
      );

      expect(summary.seatsAvailableToday(now: now), 6);
    });
  });
}
