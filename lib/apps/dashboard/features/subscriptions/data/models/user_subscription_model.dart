import '../../domain/entities/user_subscription.dart';

class UserSubscriptionModel extends UserSubscription {
  const UserSubscriptionModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.userPhone,
    required super.packageId,
    required super.packageName,
    super.routeId,
    super.routeLabel,
    super.originTripId,
    super.originBookingId,
    required super.type,
    required super.price,
    required super.currency,
    required super.totalRides,
    required super.usedRides,
    required super.remainingRides,
    super.paidAmount,
    super.remainingAmount,
    super.renewalsCount,
    required super.startDate,
    required super.endDate,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserSubscriptionModel.fromEntity(UserSubscription subscription) {
    return UserSubscriptionModel(
      id: subscription.id,
      userId: subscription.userId,
      userName: subscription.userName,
      userPhone: subscription.userPhone,
      packageId: subscription.packageId,
      packageName: subscription.packageName,
      routeId: subscription.routeId,
      routeLabel: subscription.routeLabel,
      originTripId: subscription.originTripId,
      originBookingId: subscription.originBookingId,
      type: subscription.type,
      price: subscription.price,
      currency: subscription.currency,
      totalRides: subscription.totalRides,
      usedRides: subscription.usedRides,
      remainingRides: subscription.remainingRides,
      paidAmount: subscription.paidAmount,
      remainingAmount: subscription.remainingAmount,
      renewalsCount: subscription.renewalsCount,
      startDate: subscription.startDate,
      endDate: subscription.endDate,
      status: subscription.status,
      createdAt: subscription.createdAt,
      updatedAt: subscription.updatedAt,
    );
  }
}
