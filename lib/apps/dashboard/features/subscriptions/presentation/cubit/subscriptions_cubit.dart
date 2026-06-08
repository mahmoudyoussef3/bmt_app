import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_subscription.dart';
import '../../domain/usecases/cancel_subscription_usecase.dart';
import '../../domain/usecases/create_subscription_usecase.dart';
import '../../domain/usecases/get_subscription_creation_options_usecase.dart';
import '../../domain/usecases/get_subscription_details_usecase.dart';
import '../../domain/usecases/get_subscriptions_usecase.dart';
import '../../domain/usecases/mark_subscription_ride_used_usecase.dart';
import '../../domain/usecases/renew_subscription_usecase.dart';
import 'subscriptions_state.dart';

class SubscriptionsCubit extends Cubit<SubscriptionsState> {
  final GetSubscriptionsUseCase _getSubscriptions;
  final GetSubscriptionDetailsUseCase _getDetails;
  final CreateSubscriptionUseCase _createSubscription;
  final CancelSubscriptionUseCase _cancelSubscription;
  final RenewSubscriptionUseCase _renewSubscription;
  final MarkSubscriptionRideUsedUseCase _markRideUsed;
  final GetSubscriptionCreationOptionsUseCase _getCreationOptions;

  SubscriptionsCubit({
    required GetSubscriptionsUseCase getSubscriptions,
    required GetSubscriptionDetailsUseCase getDetails,
    required CreateSubscriptionUseCase createSubscription,
    required CancelSubscriptionUseCase cancelSubscription,
    required RenewSubscriptionUseCase renewSubscription,
    required MarkSubscriptionRideUsedUseCase markRideUsed,
    required GetSubscriptionCreationOptionsUseCase getCreationOptions,
  }) : _getSubscriptions = getSubscriptions,
       _getDetails = getDetails,
       _createSubscription = createSubscription,
       _cancelSubscription = cancelSubscription,
       _renewSubscription = renewSubscription,
       _markRideUsed = markRideUsed,
       _getCreationOptions = getCreationOptions,
       super(const SubscriptionsInitial());

  Future<void> load() async {
    emit(const SubscriptionsLoading());
    try {
      final subscriptions = await _getSubscriptions();
      final options = await _getCreationOptions();
      emit(
        SubscriptionsLoaded(
          subscriptions: subscriptions,
          creationOptions: options,
        ),
      );
    } catch (error) {
      emit(SubscriptionsError(error.toString()));
    }
  }

  void updateSearch(String query) {
    final current = _asLoaded();
    if (current == null) return;
    emit(current.copyWith(searchQuery: query));
  }

  void updateStatusFilter(SubscriptionStatus? status) {
    final current = _asLoaded();
    if (current == null) return;
    emit(
      current.copyWith(statusFilter: status, clearStatusFilter: status == null),
    );
  }

  Future<void> loadDetails(String id) async {
    final current = _asLoaded();
    try {
      final subscription = await _getDetails(id);
      final subscriptions = current?.subscriptions ?? await _getSubscriptions();
      final options = current?.creationOptions ?? await _getCreationOptions();
      emit(
        SubscriptionDetailsLoaded(
          subscription: subscription,
          subscriptions: subscriptions,
          creationOptions: options,
        ),
      );
    } catch (error) {
      emit(SubscriptionsError(error.toString()));
    }
  }

  Future<void> createManualSubscription({
    required SubscriptionUserOption user,
    required SubscriptionTripOption trip,
    required SubscriptionPointOption fromPoint,
    required SubscriptionPointOption toPoint,
    required SubscriptionType type,
    required DateTime startDate,
  }) async {
    try {
      final pricing = _pricingFor(
        trip: trip,
        fromPointId: fromPoint.id,
        toPointId: toPoint.id,
        type: type,
      );
      final totalRides = ridesFor(type);
      final now = DateTime.now();
      final subscription = UserSubscription(
        id: 'sub-${now.microsecondsSinceEpoch}',
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
        type: type,
        price: pricing.price,
        currency: pricing.currency,
        totalRides: totalRides,
        usedRides: 0,
        remainingRides: totalRides,
        startDate: startDate,
        endDate: endDateFor(type, startDate),
        status: SubscriptionStatus.pendingPayment,
        createdAt: now,
        updatedAt: now,
      );
      final created = await _createSubscription(subscription);
      final subscriptions = await _getSubscriptions();
      final options = await _getCreationOptions();
      emit(
        SubscriptionsActionSuccess(
          message: 'تم إنشاء الاشتراك بانتظار الدفع',
          subscription: created,
          subscriptions: subscriptions,
          creationOptions: options,
        ),
      );
    } catch (error) {
      emit(SubscriptionsError(error.toString()));
    }
  }

  Future<void> cancel(String id) async {
    await _runAction(
      action: () => _cancelSubscription(id),
      message: 'تم إلغاء الاشتراك',
    );
  }

  Future<void> renew(String id) async {
    await _runAction(
      action: () => _renewSubscription(id),
      message: 'تم تجديد الاشتراك بانتظار الدفع',
    );
  }

  Future<void> markRideUsed(String id) async {
    await _runAction(
      action: () => _markRideUsed(id),
      message: 'تم تسجيل رحلة مستخدمة',
    );
  }

  void showList() {
    final current = state;
    if (current is SubscriptionDetailsLoaded) {
      emit(
        SubscriptionsLoaded(
          subscriptions: current.subscriptions,
          creationOptions: current.creationOptions,
        ),
      );
    } else if (current is SubscriptionsActionSuccess) {
      emit(
        SubscriptionsLoaded(
          subscriptions: current.subscriptions,
          creationOptions: current.creationOptions,
        ),
      );
    }
  }

  Future<void> _runAction({
    required Future<UserSubscription> Function() action,
    required String message,
  }) async {
    try {
      final updated = await action();
      final subscriptions = await _getSubscriptions();
      final options = await _getCreationOptions();
      emit(
        SubscriptionsActionSuccess(
          message: message,
          subscription: updated,
          subscriptions: subscriptions,
          creationOptions: options,
        ),
      );
    } catch (error) {
      emit(SubscriptionsError(error.toString()));
    }
  }

  SubscriptionsLoaded? _asLoaded() {
    final current = state;
    return switch (current) {
      SubscriptionsLoaded() => current,
      SubscriptionDetailsLoaded() => SubscriptionsLoaded(
        subscriptions: current.subscriptions,
        creationOptions: current.creationOptions,
      ),
      SubscriptionsActionSuccess() => SubscriptionsLoaded(
        subscriptions: current.subscriptions,
        creationOptions: current.creationOptions,
      ),
      _ => null,
    };
  }

  SubscriptionPricingOption _pricingFor({
    required SubscriptionTripOption trip,
    required String fromPointId,
    required String toPointId,
    required SubscriptionType type,
  }) {
    return trip.pricing.firstWhere(
      (pricing) =>
          pricing.fromPointId == fromPointId &&
          pricing.toPointId == toPointId &&
          pricing.type == type,
      orElse: () => throw StateError('لا يوجد سعر لهذا الجزء ونوع الاشتراك'),
    );
  }

  static int ridesFor(SubscriptionType type) {
    return switch (type) {
      SubscriptionType.oneTime => 1,
      SubscriptionType.fiveDays => 5,
      SubscriptionType.tenDaysMonthly => 10,
      SubscriptionType.monthly => 22,
      SubscriptionType.threeMonths => 66,
    };
  }

  static DateTime endDateFor(SubscriptionType type, DateTime startDate) {
    return switch (type) {
      SubscriptionType.oneTime => startDate,
      SubscriptionType.fiveDays => startDate.add(const Duration(days: 4)),
      SubscriptionType.tenDaysMonthly => DateTime(
        startDate.year,
        startDate.month + 1,
        0,
      ),
      SubscriptionType.monthly => DateTime(
        startDate.year,
        startDate.month + 1,
        startDate.day - 1,
      ),
      SubscriptionType.threeMonths => DateTime(
        startDate.year,
        startDate.month + 3,
        startDate.day - 1,
      ),
    };
  }
}
