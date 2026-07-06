import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_subscription.dart';
import '../../domain/usecases/cancel_subscription_usecase.dart';
import '../../domain/usecases/confirm_payment_usecase.dart';
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
  final ConfirmPaymentUseCase _confirmPayment;
  final GetSubscriptionCreationOptionsUseCase _getCreationOptions;

  SubscriptionsCubit({
    required GetSubscriptionsUseCase getSubscriptions,
    required GetSubscriptionDetailsUseCase getDetails,
    required CreateSubscriptionUseCase createSubscription,
    required CancelSubscriptionUseCase cancelSubscription,
    required RenewSubscriptionUseCase renewSubscription,
    required MarkSubscriptionRideUsedUseCase markRideUsed,
    required ConfirmPaymentUseCase confirmPayment,
    required GetSubscriptionCreationOptionsUseCase getCreationOptions,
  }) : _getSubscriptions = getSubscriptions,
       _getDetails = getDetails,
       _createSubscription = createSubscription,
       _cancelSubscription = cancelSubscription,
       _renewSubscription = renewSubscription,
       _markRideUsed = markRideUsed,
       _confirmPayment = confirmPayment,
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
    required SubscriptionPlanOption plan,
    required SubscriptionRouteOption route,
    required DateTime startDate,
  }) async {
    try {
      final now = DateTime.now();
      final endDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day + plan.days - 1,
      );
      final subscription = UserSubscription(
        id: '',
        userId: user.id,
        userName: user.name,
        userPhone: user.phone,
        tripId: '',
        routeId: plan.id, // carries package_id to the datasource
        routeName: plan.name,
        routeLabel: route.label,
        fromPointId: '',
        fromPointName: '',
        toPointId: '',
        toPointName: '',
        type: SubscriptionType.monthly,
        price: plan.price,
        currency: plan.currency,
        totalRides: plan.tripsCount,
        usedRides: 0,
        remainingRides: plan.tripsCount,
        startDate: startDate,
        endDate: endDate,
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

  Future<void> confirmPayment(String id) async {
    await _runAction(
      action: () => _confirmPayment(id),
      message: 'تم تأكيد الدفع وتفعيل الاشتراك',
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
}
