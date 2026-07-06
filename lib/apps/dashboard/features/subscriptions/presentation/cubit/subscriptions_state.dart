import '../../domain/entities/user_subscription.dart';

sealed class SubscriptionsState {
  const SubscriptionsState();
}

class SubscriptionsInitial extends SubscriptionsState {
  const SubscriptionsInitial();
}

class SubscriptionsLoading extends SubscriptionsState {
  const SubscriptionsLoading();
}

class SubscriptionsError extends SubscriptionsState {
  final String message;

  const SubscriptionsError(this.message);
}

class SubscriptionsLoaded extends SubscriptionsState {
  final List<UserSubscription> subscriptions;
  final SubscriptionCreationOptions creationOptions;
  final String searchQuery;
  final SubscriptionStatus? statusFilter;

  const SubscriptionsLoaded({
    required this.subscriptions,
    required this.creationOptions,
    this.searchQuery = '',
    this.statusFilter,
  });

  List<UserSubscription> get filteredSubscriptions {
    final normalizedQuery = searchQuery.trim();
    return subscriptions
        .where((subscription) {
          final matchesStatus =
              statusFilter == null || subscription.status == statusFilter;
          final matchesQuery =
              normalizedQuery.isEmpty ||
              subscription.userName.contains(normalizedQuery) ||
              subscription.userPhone.contains(normalizedQuery) ||
              subscription.routeLabel.contains(normalizedQuery);
          return matchesStatus && matchesQuery;
        })
        .toList(growable: false);
  }

  SubscriptionsLoaded copyWith({
    List<UserSubscription>? subscriptions,
    SubscriptionCreationOptions? creationOptions,
    String? searchQuery,
    SubscriptionStatus? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return SubscriptionsLoaded(
      subscriptions: subscriptions ?? this.subscriptions,
      creationOptions: creationOptions ?? this.creationOptions,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : statusFilter ?? this.statusFilter,
    );
  }
}

class SubscriptionDetailsLoaded extends SubscriptionsState {
  final UserSubscription subscription;
  final List<UserSubscription> subscriptions;
  final SubscriptionCreationOptions creationOptions;

  const SubscriptionDetailsLoaded({
    required this.subscription,
    required this.subscriptions,
    required this.creationOptions,
  });
}

class SubscriptionsActionSuccess extends SubscriptionsState {
  final String message;
  final UserSubscription subscription;
  final List<UserSubscription> subscriptions;
  final SubscriptionCreationOptions creationOptions;

  const SubscriptionsActionSuccess({
    required this.message,
    required this.subscription,
    required this.subscriptions,
    required this.creationOptions,
  });
}
