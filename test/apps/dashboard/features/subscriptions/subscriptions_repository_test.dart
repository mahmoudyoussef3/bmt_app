import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/subscriptions/data/datasources/subscriptions_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/data/repositories/subscriptions_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/cancel_subscription_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/create_subscription_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscription_creation_options_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscription_details_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscriptions_usecase.dart';

UserSubscription _sub(String id, SubscriptionStatus status) => UserSubscription(
  id: id,
  userId: 'usr-$id',
  userName: 'أحمد محمد',
  userPhone: '01000000000',
  tripId: '',
  routeId: '',
  routeName: 'الباقة الشهرية',
  fromPointId: '',
  fromPointName: '',
  toPointId: '',
  toPointName: '',
  type: SubscriptionType.monthly,
  price: 550,
  currency: 'ج.م',
  totalRides: 0,
  usedRides: 0,
  remainingRides: 0,
  paidAmount: 550,
  remainingAmount: 0,
  renewalsCount: 1,
  startDate: DateTime(2026, 6, 1),
  endDate: DateTime(2026, 6, 30),
  status: status,
  createdAt: DateTime(2026, 6, 1),
  updatedAt: DateTime(2026, 6, 1),
);

class _FakeSubscriptionsDatasource implements SubscriptionsDatasource {
  final List<UserSubscription> _items = [
    _sub('sub-1', SubscriptionStatus.active),
  ];

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
  Future<UserSubscription> markRideUsed(String id) async =>
      throw Exception('تتبع الرحلات غير مدعوم');

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
      );
}

class _FailingDatasource implements SubscriptionsDatasource {
  @override
  Future<UserSubscription> cancelSubscription(String id) =>
      throw StateError('x');
  @override
  Future<UserSubscription> createSubscription(UserSubscription s) =>
      throw StateError('x');
  @override
  Future<SubscriptionCreationOptions> fetchCreationOptions() =>
      throw StateError('x');
  @override
  Future<UserSubscription> fetchSubscriptionDetails(String id) =>
      throw StateError('x');
  @override
  Future<List<UserSubscription>> fetchSubscriptions() => throw StateError('x');
  @override
  Future<UserSubscription> markRideUsed(String id) => throw StateError('x');
  @override
  Future<UserSubscription> renewSubscription(String id) =>
      throw StateError('x');
}

void main() {
  group('Subscriptions clean architecture chain', () {
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
      expect(details.routeName, 'الباقة الشهرية');
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
        _sub('seed', SubscriptionStatus.active).copyWith(),
      );

      expect(options.plans, isNotEmpty);
      expect(plan.tripsCount, 44);
      expect(user.name, 'أحمد محمد');
      expect(created.id, 'sub-new');
    });

    test('cancels a subscription', () async {
      final repository = SubscriptionsRepositoryImpl(
        _FakeSubscriptionsDatasource(),
      );
      final cancel = CancelSubscriptionUseCase(repository);
      final cancelled = await cancel('sub-1');
      expect(cancelled.status, SubscriptionStatus.cancelled);
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
  });
}
