import '../../domain/entities/subscription_trip.dart';
import '../../domain/entities/user_subscription.dart';

/// Why a subscription shows up on a given trip's board.
///
/// A subscription is not owned by one trip — a ten-ride package spans many
/// departures — so "the subscribers of this trip" is a relationship with three
/// distinct, all-real meanings rather than a single foreign key.
enum TripSubscriberLink {
  /// A ride has already been burnt off this subscription for this trip
  /// (`subscription_ride_usage`). The strongest link: they are on board.
  rode('تم تسجيل رحلته', 'استُهلكت رحلة من رصيد الاشتراك على هذه الرحلة'),

  /// This trip's booking is what created the subscription
  /// (`subscriptions.origin_trip_id`).
  booked('اشترك من هذه الرحلة', 'تم شراء الباقة أثناء الحجز على هذه الرحلة'),

  /// Subscribed to the route this trip runs, with the trip's date inside their
  /// plan window — entitled to board, not yet recorded.
  eligible('مؤهل للركوب', 'اشتراك سارٍ على نفس خط السير ويشمل تاريخ الرحلة');

  final String label;
  final String description;

  const TripSubscriberLink(this.label, this.description);
}

/// One subscriber as they relate to a single trip.
class TripSubscriber {
  final UserSubscription subscription;

  /// Every reason this subscriber is on the board, strongest first.
  final List<TripSubscriberLink> links;

  /// When their ride on this trip was recorded, if it was.
  final DateTime? rideRecordedAt;

  const TripSubscriber({
    required this.subscription,
    required this.links,
    this.rideRecordedAt,
  });

  TripSubscriberLink get primaryLink => links.first;

  bool get hasRidden => links.contains(TripSubscriberLink.rode);

  /// Whether the office can still record this subscriber's ride on this trip:
  /// not already recorded, and the subscription itself is usable today. Mirrors
  /// exactly what `consume_subscription_ride` will accept.
  bool get canRecordRide => !hasRidden && subscription.canConsumeRide;
}

/// The whole picture for one departure: who is expected, who is on board, and
/// what is still owed.
class TripSubscriberBoard {
  final SubscriptionTrip trip;
  final List<TripSubscriber> subscribers;

  const TripSubscriberBoard({required this.trip, required this.subscribers});

  int get expectedCount => subscribers.length;

  int get checkedInCount =>
      subscribers.where((subscriber) => subscriber.hasRidden).length;

  int get pendingCheckInCount =>
      subscribers.where((subscriber) => subscriber.canRecordRide).length;

  double get outstandingAmount => subscribers.fold<double>(
    0,
    (sum, subscriber) => sum + subscriber.subscription.outstandingAmount,
  );

  int get unpaidCount => subscribers
      .where((subscriber) => subscriber.subscription.hasOutstandingBalance)
      .length;

  /// Packages represented on this trip, with how many subscribers hold each —
  /// the answer to "subscribed for which package" at a glance.
  Map<String, int> get packageBreakdown {
    final counts = <String, int>{};
    for (final subscriber in subscribers) {
      final name = subscriber.subscription.packageName;
      counts.update(name, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  /// Builds the board by resolving all three link types against real data.
  ///
  /// [rideUsage] is the ledger; only rows for this trip matter here.
  static TripSubscriberBoard build({
    required SubscriptionTrip trip,
    required List<UserSubscription> subscriptions,
    required List<SubscriptionRideUsage> rideUsage,
  }) {
    final ridesOnTrip = <String, DateTime>{};
    for (final usage in rideUsage) {
      if (usage.tripId != trip.id) continue;
      final existing = ridesOnTrip[usage.subscriptionId];
      if (existing == null || usage.usedAt.isAfter(existing)) {
        ridesOnTrip[usage.subscriptionId] = usage.usedAt;
      }
    }

    final subscribers = <TripSubscriber>[];
    for (final subscription in subscriptions) {
      final links = <TripSubscriberLink>[];

      if (ridesOnTrip.containsKey(subscription.id)) {
        links.add(TripSubscriberLink.rode);
      }
      if (subscription.originTripId == trip.id) {
        links.add(TripSubscriberLink.booked);
      }
      if (_isEligible(subscription, trip)) {
        links.add(TripSubscriberLink.eligible);
      }

      if (links.isEmpty) continue;
      subscribers.add(
        TripSubscriber(
          subscription: subscription,
          links: links,
          rideRecordedAt: ridesOnTrip[subscription.id],
        ),
      );
    }

    // Work first: who still needs checking in, then who is already on board,
    // then the rest — with the strongest link deciding ties.
    subscribers.sort((a, b) {
      final byLink = a.primaryLink.index.compareTo(b.primaryLink.index);
      if (byLink != 0) return byLink;
      return a.subscription.userName.compareTo(b.subscription.userName);
    });

    return TripSubscriberBoard(trip: trip, subscribers: subscribers);
  }

  /// Entitled to ride: same route, active, and the departure date falls inside
  /// the plan window. A cancelled or expired plan entitles nobody, which is why
  /// status is part of the test and not just the dates.
  static bool _isEligible(
    UserSubscription subscription,
    SubscriptionTrip trip,
  ) {
    if (subscription.routeId.isEmpty || trip.routeId.isEmpty) return false;
    if (subscription.routeId != trip.routeId) return false;
    if (subscription.status != SubscriptionStatus.active) return false;

    final date = trip.date;
    if (date == null) return false;
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      subscription.startDate.year,
      subscription.startDate.month,
      subscription.startDate.day,
    );
    final end = DateTime(
      subscription.endDate.year,
      subscription.endDate.month,
      subscription.endDate.day,
    );
    return !day.isBefore(start) && !day.isAfter(end);
  }
}
