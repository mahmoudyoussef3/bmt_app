import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/subscriptions/data/datasources/mock_subscriptions_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/data/repositories/subscriptions_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/cancel_subscription_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/create_subscription_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscription_creation_options_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscription_details_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscriptions_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/mark_subscription_ride_used_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/renew_subscription_usecase.dart';

void main() {
  group('Subscriptions clean architecture chain', () {
    test('loads subscribed users with segment and pricing details', () async {
      final repository = SubscriptionsRepositoryImpl(
        MockSubscriptionsDatasource(),
      );
      final getSubscriptions = GetSubscriptionsUseCase(repository);
      final getDetails = GetSubscriptionDetailsUseCase(repository);

      final subscriptions = await getSubscriptions();
      final details = await getDetails(subscriptions.first.id);

      expect(subscriptions, isNotEmpty);
      expect(details.userName, 'أحمد محمد');
      expect(details.routeName, 'بنها → التجمع الخامس');
      expect(details.fromPointName, 'بنها');
      expect(details.toPointName, 'رمسيس');
      expect(details.type, SubscriptionType.fiveDays);
      expect(details.price, 280);
      expect(details.remainingRides, 3);
      expect(details.status, SubscriptionStatus.active);
    });

    test('creates a subscription using a trip-scoped pricing option', () async {
      final repository = SubscriptionsRepositoryImpl(
        MockSubscriptionsDatasource(),
      );
      final getOptions = GetSubscriptionCreationOptionsUseCase(repository);
      final createSubscription = CreateSubscriptionUseCase(repository);
      final getSubscriptions = GetSubscriptionsUseCase(repository);

      final options = await getOptions();
      final user = options.users.first;
      final trip = options.trips.first;
      final pricing = trip.pricing.firstWhere(
        (item) => item.type == SubscriptionType.monthly,
      );
      final fromPoint = trip.points.firstWhere(
        (point) => point.id == pricing.fromPointId,
      );
      final toPoint = trip.points.firstWhere(
        (point) => point.id == pricing.toPointId,
      );

      final created = await createSubscription(
        UserSubscription(
          id: 'sub-test',
          userId: user.id,
          userName: user.name,
          userPhone: user.phone,
          tripId: trip.id,
          routeId: trip.routeId,
          routeName: trip.routeName,
          fromPointId: fromPoint.id,
          fromPointName: fromPoint.name,
          toPointId: toPoint.id,
          toPointName: toPoint.name,
          type: pricing.type,
          price: pricing.price,
          currency: pricing.currency,
          totalRides: 22,
          usedRides: 0,
          remainingRides: 22,
          startDate: DateTime(2026, 6, 9),
          endDate: DateTime(2026, 7, 8),
          status: SubscriptionStatus.pendingPayment,
          createdAt: DateTime(2026, 6, 9),
          updatedAt: DateTime(2026, 6, 9),
        ),
      );

      expect(created.price, pricing.price);
      expect(created.routeId, trip.routeId);
      expect(created.status, SubscriptionStatus.pendingPayment);
      expect((await getSubscriptions()).first.id, 'sub-test');
    });

    test('updates cancellation renewal and used ride counts', () async {
      final repository = SubscriptionsRepositoryImpl(
        MockSubscriptionsDatasource(),
      );
      final cancel = CancelSubscriptionUseCase(repository);
      final renew = RenewSubscriptionUseCase(repository);
      final markRideUsed = MarkSubscriptionRideUsedUseCase(repository);

      final cancelled = await cancel('sub-1001');
      expect(cancelled.status, SubscriptionStatus.cancelled);

      final renewed = await renew('sub-1003');
      expect(renewed.status, SubscriptionStatus.pendingPayment);
      expect(renewed.usedRides, 0);
      expect(renewed.remainingRides, renewed.totalRides);

      final used = await markRideUsed('sub-1005');
      expect(used.usedRides, 1);
      expect(used.remainingRides, 0);
      expect(used.status, SubscriptionStatus.expired);

      expect(() => markRideUsed('sub-1005'), throwsA(isA<Exception>()));
    });
  });
}
