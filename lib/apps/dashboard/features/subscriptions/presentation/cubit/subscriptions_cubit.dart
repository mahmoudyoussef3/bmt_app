import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/subscription_trip.dart';
import '../../domain/entities/user_subscription.dart';
import '../../domain/usecases/cancel_subscription_usecase.dart';
import '../../domain/usecases/confirm_payment_usecase.dart';
import '../../domain/usecases/create_subscription_usecase.dart';
import '../../domain/usecases/get_subscription_creation_options_usecase.dart';
import '../../domain/usecases/get_subscription_details_usecase.dart';
import '../../domain/usecases/get_subscription_ride_usage_usecase.dart';
import '../../domain/usecases/get_subscription_trips_usecase.dart';
import '../../domain/usecases/get_subscriptions_usecase.dart';
import '../../domain/usecases/mark_subscription_ride_used_usecase.dart';
import '../../domain/usecases/renew_subscription_usecase.dart';
import '../models/subscription_filters.dart';
import '../models/subscription_queue_tab.dart';
import '../models/subscription_sort.dart';
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
  final GetSubscriptionTripsUseCase _getTrips;
  final GetSubscriptionRideUsageUseCase _getRideUsage;

  SubscriptionsCubit({
    required GetSubscriptionsUseCase getSubscriptions,
    required GetSubscriptionDetailsUseCase getDetails,
    required CreateSubscriptionUseCase createSubscription,
    required CancelSubscriptionUseCase cancelSubscription,
    required RenewSubscriptionUseCase renewSubscription,
    required MarkSubscriptionRideUsedUseCase markRideUsed,
    required ConfirmPaymentUseCase confirmPayment,
    required GetSubscriptionCreationOptionsUseCase getCreationOptions,
    required GetSubscriptionTripsUseCase getTrips,
    required GetSubscriptionRideUsageUseCase getRideUsage,
  }) : _getSubscriptions = getSubscriptions,
       _getDetails = getDetails,
       _createSubscription = createSubscription,
       _cancelSubscription = cancelSubscription,
       _renewSubscription = renewSubscription,
       _markRideUsed = markRideUsed,
       _confirmPayment = confirmPayment,
       _getCreationOptions = getCreationOptions,
       _getTrips = getTrips,
       _getRideUsage = getRideUsage,
       super(const SubscriptionsInitial());

  Future<void> load() async {
    emit(const SubscriptionsLoading());
    try {
      final results = await Future.wait([
        _getSubscriptions(),
        _getCreationOptions(),
        _getTrips(),
        _getRideUsage(),
      ]);
      emit(
        SubscriptionsLoaded(
          subscriptions: results[0] as List<UserSubscription>,
          creationOptions: results[1] as SubscriptionCreationOptions,
          trips: results[2] as List<SubscriptionTrip>,
          rideUsage: results[3] as List<SubscriptionRideUsage>,
        ),
      );
    } catch (error) {
      emit(SubscriptionsError(_message(error)));
    }
  }

  // ── Filtering / view state ────────────────────────────────────────────────

  void updateFilters(SubscriptionFilters filters) {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(filters: filters));
  }

  void updateSearch(String query) {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(filters: current.filters.copyWith(search: query)));
  }

  /// Focus one departure. Selecting a trip also drops any route filter: the
  /// trip already implies its route, and leaving both on reads as a bug when
  /// the two disagree.
  void selectTrip(String? tripId) {
    final current = _loaded;
    if (current == null) return;
    emit(
      current.copyWith(
        filters: current.filters.copyWith(
          tripId: tripId ?? '',
          routeId: tripId == null || tripId.isEmpty
              ? current.filters.routeId
              : '',
        ),
      ),
    );
  }

  void clearFilters() {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(filters: const SubscriptionFilters()));
  }

  void switchTab(SubscriptionQueueTab tab) {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(activeTab: tab));
  }

  /// Re-picking the active field flips its direction; a new field starts in the
  /// direction that puts its interesting rows first.
  void sortBy(SubscriptionSortField field) {
    final current = _loaded;
    if (current == null) return;
    final ascending = current.sortField == field
        ? !current.sortAscending
        : field.defaultAscending;
    emit(current.copyWith(sortField: field, sortAscending: ascending));
  }

  void select(String? id) {
    final current = _loaded;
    if (current == null) return;
    emit(
      id == null
          ? current.copyWith(clearSelection: true)
          : current.copyWith(selectedId: id),
    );
  }

  void clearActionFeedback() {
    final current = _loaded;
    if (current == null) return;
    if (current.actionError == null && current.actionMessage == null) return;
    emit(current.copyWith(clearActionError: true, clearActionMessage: true));
  }

  /// Refetches one subscriber's row. Used by the detail pane so opening a
  /// subscriber shows server truth rather than whatever the list last cached.
  Future<void> loadDetails(String id) async {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(selectedId: id));
    try {
      final fresh = await _getDetails(id);
      final latest = _loaded;
      if (latest == null) return;
      emit(latest.copyWith(subscriptions: _replace(latest, fresh)));
    } catch (error) {
      final latest = _loaded;
      if (latest == null) return;
      emit(latest.copyWith(actionError: _message(error)));
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> createManualSubscription({
    required SubscriptionUserOption user,
    required SubscriptionPlanOption plan,
    required SubscriptionRouteOption route,
    required DateTime startDate,
  }) async {
    final now = DateTime.now();
    final endDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day + plan.days - 1,
    );
    final draft = UserSubscription(
      id: '',
      userId: user.id,
      userName: user.name,
      userPhone: user.phone,
      packageId: plan.id,
      packageName: plan.name,
      routeId: route.id,
      routeLabel: route.label,
      type: SubscriptionType.monthly,
      price: plan.price,
      currency: plan.currency,
      totalRides: plan.tripsCount,
      usedRides: 0,
      remainingRides: plan.tripsCount,
      remainingAmount: plan.price,
      startDate: startDate,
      endDate: endDate,
      status: SubscriptionStatus.pendingPayment,
      createdAt: now,
      updatedAt: now,
    );

    await _runAction(
      action: () => _createSubscription(draft),
      message: 'تم إنشاء الاشتراك بانتظار الدفع',
    );
  }

  Future<void> cancel(String id) => _runAction(
    action: () => _cancelSubscription(id),
    message: 'تم إلغاء الاشتراك',
  );

  Future<void> renew(String id) => _runAction(
    action: () => _renewSubscription(id),
    message: 'تم إنشاء تجديد بانتظار الدفع',
  );

  Future<void> confirmPayment(String id) => _runAction(
    action: () => _confirmPayment(id),
    message: 'تم تأكيد الدفع وتفعيل الاشتراك',
  );

  /// Burns a ride. [tripId] is what attributes it to a departure — the trip
  /// board always passes the trip in focus, so the ledger stays complete.
  Future<void> markRideUsed(String id, {String? tripId}) => _runAction(
    action: () => _markRideUsed(id, tripId: tripId),
    message: tripId == null
        ? 'تم تسجيل رحلة مستخدمة'
        : 'تم تسجيل ركوب المشترك على هذه الرحلة',
  );

  /// Records a ride for a whole departure at once.
  ///
  /// Each subscriber still goes through the same per-subscription RPC — there
  /// is no bulk RPC to hide a partial failure behind — so the outcome is
  /// reported as "recorded N, M failed" rather than as one all-or-nothing
  /// result that would not be true.
  Future<void> markRidesUsedForTrip({
    required List<String> subscriptionIds,
    required String tripId,
  }) async {
    final current = _loaded;
    if (current == null || current.isProcessing) return;
    if (subscriptionIds.isEmpty) return;

    emit(
      current.copyWith(
        isProcessing: true,
        clearActionError: true,
        clearActionMessage: true,
      ),
    );

    var recorded = 0;
    String? firstFailure;
    for (final id in subscriptionIds) {
      try {
        await _markRideUsed(id, tripId: tripId);
        recorded++;
      } catch (error) {
        firstFailure ??= _message(error);
      }
    }

    final failed = subscriptionIds.length - recorded;
    try {
      final subscriptions = await _getSubscriptions();
      final rideUsage = await _getRideUsage();
      final latest = _loaded ?? current;
      emit(
        latest.copyWith(
          subscriptions: subscriptions,
          rideUsage: rideUsage,
          isProcessing: false,
          actionMessage: recorded > 0
              ? 'تم تسجيل ركوب ${recorded.toString()} مشترك'
              : null,
          actionError: failed > 0
              ? 'تعذر تسجيل ${failed.toString()} مشترك — $firstFailure'
              : null,
        ),
      );
    } catch (error) {
      final latest = _loaded ?? current;
      emit(latest.copyWith(actionError: _message(error), isProcessing: false));
    }
  }

  /// Every action follows the same shape: run it, then refetch the data it
  /// could have changed, and keep the workspace intact on failure.
  Future<void> _runAction({
    required Future<UserSubscription> Function() action,
    required String message,
  }) async {
    final current = _loaded;
    if (current == null) return;
    if (current.isProcessing) return;

    emit(
      current.copyWith(
        isProcessing: true,
        clearActionError: true,
        clearActionMessage: true,
      ),
    );
    try {
      await action();
      final subscriptions = await _getSubscriptions();
      final rideUsage = await _getRideUsage();
      final latest = _loaded ?? current;
      emit(
        latest.copyWith(
          subscriptions: subscriptions,
          rideUsage: rideUsage,
          actionMessage: message,
          isProcessing: false,
        ),
      );
    } catch (error) {
      final latest = _loaded ?? current;
      emit(latest.copyWith(actionError: _message(error), isProcessing: false));
    }
  }

  List<UserSubscription> _replace(
    SubscriptionsLoaded state,
    UserSubscription fresh,
  ) {
    return [
      for (final subscription in state.subscriptions)
        if (subscription.id == fresh.id) fresh else subscription,
    ];
  }

  SubscriptionsLoaded? get _loaded {
    final current = state;
    return current is SubscriptionsLoaded ? current : null;
  }

  /// Repository errors are already Arabic; `Exception: ` is Dart noise the
  /// operator should never see.
  static String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
