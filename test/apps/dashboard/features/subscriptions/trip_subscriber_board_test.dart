import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/subscription_trip.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/presentation/models/trip_subscriber.dart';

import 'subscriptions_test_fixtures.dart';

void main() {
  final trip = tripFixture(
    id: 'trip-1',
    routeId: 'route-1',
    date: DateTime(2026, 6, 15),
  );

  // Recording a ride is only possible while the plan is live *today* — the RPC
  // applies that rule, so anything asserting on check-in has to run against a
  // window containing the current date rather than a fixed month.
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final liveTrip = tripFixture(id: 'trip-1', routeId: 'route-1', date: today);
  final liveWindowStart = today.subtract(const Duration(days: 5));
  final liveWindowEnd = today.add(const Duration(days: 5));

  TripSubscriberBoard board(
    List<UserSubscription> subscriptions, {
    List<SubscriptionRideUsage> usage = const [],
    SubscriptionTrip? onTrip,
  }) {
    return TripSubscriberBoard.build(
      trip: onTrip ?? trip,
      subscriptions: subscriptions,
      rideUsage: usage,
    );
  }

  group('who counts as a subscriber on a trip', () {
    test(
      'an active subscriber on the route inside their window is eligible',
      () {
        final result = board([
          subscriptionFixture(
            id: 'sub-1',
            status: SubscriptionStatus.active,
            startDate: DateTime(2026, 6, 1),
            endDate: DateTime(2026, 6, 30),
          ),
        ]);

        expect(
          result.subscribers.single.primaryLink,
          TripSubscriberLink.eligible,
        );
        expect(result.expectedCount, 1);
      },
    );

    test('the trip that sold the package links even off-route', () {
      final result = board([
        subscriptionFixture(
          id: 'sub-1',
          status: SubscriptionStatus.expired,
          routeId: 'route-other',
          originTripId: 'trip-1',
        ),
      ]);

      expect(result.subscribers.single.primaryLink, TripSubscriberLink.booked);
    });

    test('a recorded ride outranks every other link', () {
      final result = board(
        [
          subscriptionFixture(
            id: 'sub-1',
            status: SubscriptionStatus.active,
            originTripId: 'trip-1',
          ),
        ],
        usage: [
          SubscriptionRideUsage(
            id: 'usage-1',
            subscriptionId: 'sub-1',
            tripId: 'trip-1',
            usedAt: DateTime(2026, 6, 15, 8, 5),
          ),
        ],
      );

      final subscriber = result.subscribers.single;
      expect(subscriber.primaryLink, TripSubscriberLink.rode);
      expect(subscriber.hasRidden, isTrue);
      expect(subscriber.canRecordRide, isFalse);
      expect(subscriber.rideRecordedAt, DateTime(2026, 6, 15, 8, 5));
      expect(result.checkedInCount, 1);
      expect(result.pendingCheckInCount, 0);
    });

    test('a ride on a different trip does not check them in on this one', () {
      final result = board(
        [
          subscriptionFixture(
            id: 'sub-1',
            status: SubscriptionStatus.active,
            startDate: liveWindowStart,
            endDate: liveWindowEnd,
          ),
        ],
        onTrip: liveTrip,
        usage: [
          SubscriptionRideUsage(
            id: 'usage-1',
            subscriptionId: 'sub-1',
            tripId: 'trip-2',
            usedAt: today.subtract(const Duration(days: 1)),
          ),
        ],
      );

      expect(result.subscribers.single.hasRidden, isFalse);
      expect(result.pendingCheckInCount, 1);
    });

    test(
      'a past departure still lists its subscribers but blocks check-in',
      () {
        // The plan covered the trip's date, so they were entitled to ride it —
        // but the ride RPC only accepts a plan that is live today, so the board
        // must not offer an action the database would refuse.
        final result = board([
          subscriptionFixture(
            id: 'sub-1',
            status: SubscriptionStatus.active,
            startDate: DateTime(2026, 6, 1),
            endDate: DateTime(2026, 6, 30),
          ),
        ]);

        final subscriber = result.subscribers.single;
        expect(subscriber.primaryLink, TripSubscriberLink.eligible);
        expect(subscriber.canRecordRide, isFalse);
      },
    );

    test('a trip date outside the plan window is not eligible', () {
      final result = board([
        subscriptionFixture(
          id: 'sub-1',
          status: SubscriptionStatus.active,
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        ),
      ]);

      expect(result.subscribers, isEmpty);
    });

    test('a cancelled subscription on the route is not eligible', () {
      final result = board([
        subscriptionFixture(
          id: 'sub-1',
          status: SubscriptionStatus.cancelled,
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 30),
        ),
      ]);

      expect(result.subscribers, isEmpty);
    });

    test('a subscription with no route link never matches by route', () {
      final result = board([
        subscriptionFixture(
          id: 'sub-1',
          status: SubscriptionStatus.active,
          routeId: '',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 30),
        ),
      ]);

      expect(result.subscribers, isEmpty);
    });
  });

  group('what the board tells the operator', () {
    test('packages are broken down by how many subscribers hold each', () {
      final result = board([
        subscriptionFixture(
          id: 'sub-1',
          status: SubscriptionStatus.active,
          packageName: 'شهري',
        ),
        subscriptionFixture(
          id: 'sub-2',
          status: SubscriptionStatus.active,
          packageName: 'شهري',
        ),
        subscriptionFixture(
          id: 'sub-3',
          status: SubscriptionStatus.active,
          packageName: 'أسبوعي',
        ),
      ]);

      expect(result.packageBreakdown, {'شهري': 2, 'أسبوعي': 1});
    });

    test('outstanding money is summed across the departure', () {
      final result = board([
        subscriptionFixture(
          id: 'sub-1',
          status: SubscriptionStatus.active,
          paidAmount: 300,
          remainingAmount: 250,
        ),
        subscriptionFixture(
          id: 'sub-2',
          status: SubscriptionStatus.active,
          paidAmount: 550,
          remainingAmount: 0,
        ),
      ]);

      expect(result.outstandingAmount, 250);
      expect(result.unpaidCount, 1);
    });

    test('a spent ride balance blocks check-in', () {
      final result = board([
        subscriptionFixture(
          id: 'sub-1',
          status: SubscriptionStatus.active,
          totalRides: 4,
          usedRides: 4,
        ),
      ]);

      expect(result.subscribers.single.canRecordRide, isFalse);
      expect(result.pendingCheckInCount, 0);
    });
  });
}
