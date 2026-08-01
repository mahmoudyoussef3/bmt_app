import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/subscriptions/data/datasources/subscriptions_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/data/repositories/subscriptions_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/subscription_trip.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/cancel_subscription_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/create_subscription_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscription_creation_options_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscription_details_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscription_ride_usage_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscription_trips_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscriptions_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/mark_subscription_ride_used_usecase.dart';

import 'subscriptions_test_fixtures.dart';

class _FakeSubscriptionsDatasource implements SubscriptionsDatasource {
  final List<UserSubscription> _items = [
    subscriptionFixture(id: 'sub-1', status: SubscriptionStatus.active),
  ];

  /// (subscriptionId, tripId) pairs the fake was asked to record.
  final List<(String, String?)> recordedRides = [];

  @override
  Future<List<UserSubscription>> fetchSubscriptions() async =>
      List.unmodifiable(_items);

  @override
  Future<UserSubscription> fetchSubscriptionDetails(String id) async =>
      _items.firstWhere((s) => s.id == id);

  @override
  Future<UserSubscription> createSubscription(
    UserSubscription subscription,
  ) async {
    final created = subscription.copyWith(id: 'sub-new');
    _items.insert(0, created);
    return created;
  }

  @override
  Future<UserSubscription> cancelSubscription(String id) async {
    final updated = _items
        .firstWhere((s) => s.id == id)
        .copyWith(status: SubscriptionStatus.cancelled);
    _items[_items.indexWhere((s) => s.id == id)] = updated;
    return updated;
  }

  @override
  Future<UserSubscription> renewSubscription(String id) async => _items
      .firstWhere((s) => s.id == id)
      .copyWith(status: SubscriptionStatus.active, renewalsCount: 2);

  @override
  Future<UserSubscription> markRideUsed(String id, {String? tripId}) async {
    recordedRides.add((id, tripId));
    final current = _items.firstWhere((s) => s.id == id);
    return current.copyWith(
      usedRides: current.usedRides + 1,
      remainingRides: current.remainingRides - 1,
    );
  }

  @override
  Future<UserSubscription> confirmPayment(String id) async =>
      throw Exception('not used in fake');

  @override
  Future<SubscriptionCreationOptions> fetchCreationOptions() async =>
      const SubscriptionCreationOptions(
        users: [
          SubscriptionUserOption(id: 'usr-1', name: 'أحمد محمد', phone: '0100'),
        ],
        plans: [
          SubscriptionPlanOption(
            id: 'pkg-1',
            name: 'الباقة الشهرية',
            price: 550,
            currency: 'ج.م',
            days: 30,
            tripsCount: 44,
          ),
        ],
        routes: [
          SubscriptionRouteOption(id: 'route-1', label: 'بنها - القاهرة'),
        ],
      );

  @override
  Future<List<SubscriptionTrip>> fetchTrips() async => [
    tripFixture(id: 'trip-1', routeId: 'route-1'),
  ];

  @override
  Future<List<SubscriptionRideUsage>> fetchRideUsage() async => [
    SubscriptionRideUsage(
      id: 'usage-1',
      subscriptionId: 'sub-1',
      tripId: 'trip-1',
      usedAt: DateTime(2026, 7, 20, 8, 30),
    ),
  ];
}

class _FailingDatasource implements SubscriptionsDatasource {
  /// What the datasource throws. Defaults to a generic failure; individual
  /// tests swap it for a specific database error string.
  final Object error;

  const _FailingDatasource([this.error = 'boom']);

  Never _fail() => throw StateError(error.toString());

  @override
  Future<UserSubscription> cancelSubscription(String id) => _fail();
  @override
  Future<UserSubscription> createSubscription(UserSubscription s) => _fail();
  @override
  Future<SubscriptionCreationOptions> fetchCreationOptions() => _fail();
  @override
  Future<UserSubscription> fetchSubscriptionDetails(String id) => _fail();
  @override
  Future<List<UserSubscription>> fetchSubscriptions() => _fail();
  @override
  Future<UserSubscription> markRideUsed(String id, {String? tripId}) => _fail();
  @override
  Future<UserSubscription> renewSubscription(String id) => _fail();
  @override
  Future<UserSubscription> confirmPayment(String id) => _fail();
  @override
  Future<List<SubscriptionTrip>> fetchTrips() => _fail();
  @override
  Future<List<SubscriptionRideUsage>> fetchRideUsage() => _fail();
}

void main() {
  group('Subscriptions clean architecture chain', () {
    test('validity includes the subscription end date', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final activeToday = subscriptionFixture(
        id: 'today',
        status: SubscriptionStatus.active,
      ).copyWith(endDate: today);
      final expiredYesterday = activeToday.copyWith(
        endDate: today.subtract(const Duration(days: 1)),
      );

      expect(activeToday.remainingDays, 1);
      expect(expiredYesterday.remainingDays, 0);
    });

    test('loads subscribers and details from the datasource', () async {
      final repository = SubscriptionsRepositoryImpl(
        _FakeSubscriptionsDatasource(),
      );
      final getSubscriptions = GetSubscriptionsUseCase(repository);
      final getDetails = GetSubscriptionDetailsUseCase(repository);

      final subscriptions = await getSubscriptions();
      final details = await getDetails(subscriptions.first.id);

      expect(subscriptions, isNotEmpty);
      expect(details.userName, 'أحمد محمد');
      expect(details.packageName, 'الباقة الشهرية');
      expect(details.price, 550);
      expect(details.status, SubscriptionStatus.active);
    });

    test('creates a subscription from real creation options', () async {
      final repository = SubscriptionsRepositoryImpl(
        _FakeSubscriptionsDatasource(),
      );
      final getOptions = GetSubscriptionCreationOptionsUseCase(repository);
      final createSubscription = CreateSubscriptionUseCase(repository);

      final options = await getOptions();
      final user = options.users.first;
      final plan = options.plans.first;

      final created = await createSubscription(
        subscriptionFixture(id: 'seed', status: SubscriptionStatus.active),
      );

      expect(options.plans, isNotEmpty);
      expect(plan.tripsCount, 44);
      expect(user.name, 'أحمد محمد');
      expect(created.id, 'sub-new');
    });

    test('route options come from the office route table', () async {
      final repository = SubscriptionsRepositoryImpl(
        _FakeSubscriptionsDatasource(),
      );
      final options = await GetSubscriptionCreationOptionsUseCase(repository)();

      expect(options.routes.single.id, 'route-1');
    });

    test('cancels a subscription', () async {
      final repository = SubscriptionsRepositoryImpl(
        _FakeSubscriptionsDatasource(),
      );
      final cancel = CancelSubscriptionUseCase(repository);
      final cancelled = await cancel('sub-1');
      expect(cancelled.status, SubscriptionStatus.cancelled);
    });

    test('a consumed ride is attributed to the trip it was spent on', () async {
      final datasource = _FakeSubscriptionsDatasource();
      final repository = SubscriptionsRepositoryImpl(datasource);
      final markRideUsed = MarkSubscriptionRideUsedUseCase(repository);

      await markRideUsed('sub-1', tripId: 'trip-1');

      expect(datasource.recordedRides, [('sub-1', 'trip-1')]);
    });

    test('loads the office trips and the ride ledger', () async {
      final repository = SubscriptionsRepositoryImpl(
        _FakeSubscriptionsDatasource(),
      );

      final trips = await GetSubscriptionTripsUseCase(repository)();
      final usage = await GetSubscriptionRideUsageUseCase(repository)();

      expect(trips.single.id, 'trip-1');
      expect(usage.single.tripId, 'trip-1');
    });

    test('maps datasource failures to an Arabic repository error', () async {
      final repository = SubscriptionsRepositoryImpl(_FailingDatasource());
      final getSubscriptions = GetSubscriptionsUseCase(repository);
      expect(
        getSubscriptions.call,
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('تعذر تحميل الاشتراكات'),
          ),
        ),
      );
    });

    test('a duplicate ride on the same trip says so, specifically', () async {
      final repository = SubscriptionsRepositoryImpl(
        const _FailingDatasource('ride_already_recorded_for_trip'),
      );

      expect(
        () => repository.markRideUsed('sub-1', tripId: 'trip-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('تم تسجيل رحلة لهذا المشترك على هذه الرحلة بالفعل'),
          ),
        ),
      );
    });
  });
}
