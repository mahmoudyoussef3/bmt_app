import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/subscription_trip.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/user_subscription.dart';

/// Shared builders so every subscriptions test starts from the same shape and
/// only states the fields it actually cares about.
UserSubscription subscriptionFixture({
  required String id,
  required SubscriptionStatus status,
  String userName = 'أحمد محمد',
  String userPhone = '01000000000',
  String packageName = 'الباقة الشهرية',
  String routeId = 'route-1',
  String routeLabel = 'بنها - القاهرة',
  String originTripId = '',
  double price = 550,
  double paidAmount = 550,
  double remainingAmount = 0,
  int totalRides = 20,
  int usedRides = 0,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final start = startDate ?? DateTime(2026, 6, 1);
  final end = endDate ?? DateTime(2026, 6, 30);
  return UserSubscription(
    id: id,
    userId: 'usr-$id',
    userName: userName,
    userPhone: userPhone,
    packageId: 'pkg-1',
    packageName: packageName,
    routeId: routeId,
    routeLabel: routeLabel,
    originTripId: originTripId,
    type: SubscriptionType.monthly,
    price: price,
    currency: 'ج.م',
    totalRides: totalRides,
    usedRides: usedRides,
    remainingRides: totalRides - usedRides,
    paidAmount: paidAmount,
    remainingAmount: remainingAmount,
    renewalsCount: 1,
    startDate: start,
    endDate: end,
    status: status,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

SubscriptionTrip tripFixture({
  required String id,
  required String routeId,
  String code = 'TR-100',
  String routeName = 'بنها - القاهرة',
  DateTime? date,
  String departureTime = '08:00:00',
  String status = 'scheduled',
}) {
  return SubscriptionTrip(
    id: id,
    code: code,
    routeId: routeId,
    routeName: routeName,
    date: date ?? DateTime(2026, 6, 15),
    departureTime: departureTime,
    status: status,
  );
}
