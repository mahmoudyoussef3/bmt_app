import '../../domain/entities/subscription_trip.dart';
import '../../domain/entities/user_subscription.dart';
import '../models/subscription_filters.dart';
import '../models/subscription_queue_tab.dart';
import '../models/subscription_sort.dart';
import '../models/trip_subscriber.dart';
import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';

sealed class SubscriptionsState {
  const SubscriptionsState();
}

class SubscriptionsInitial extends SubscriptionsState {
  const SubscriptionsInitial();
}

class SubscriptionsLoading extends SubscriptionsState {
  const SubscriptionsLoading();
}

/// Only a failed *load* lands here. A failed action keeps the workspace and
/// surfaces `SubscriptionsLoaded.actionError` instead, so one bad RPC never
/// costs the operator their filters, tab and open subscriber.
class SubscriptionsError extends SubscriptionsState {
  final String message;

  const SubscriptionsError(this.message);
}

class SubscriptionsLoaded extends SubscriptionsState {
  final List<UserSubscription> subscriptions;
  final List<SubscriptionTrip> trips;
  final List<SubscriptionRideUsage> rideUsage;
  final SubscriptionCreationOptions creationOptions;

  /// True when the query came back full at [DashboardQueryCaps.subscriptions],
  /// so this book is the newest slice rather than every subscription ever sold.
  bool get capReached =>
      subscriptions.length >= DashboardQueryCaps.subscriptions;

  final SubscriptionFilters filters;
  final SubscriptionQueueTab activeTab;
  final SubscriptionSortField sortField;
  final bool sortAscending;

  /// The subscriber open in the detail pane, by id — an id rather than the
  /// entity so a reload after an action keeps the pane on the *fresh* row.
  final String? selectedId;

  final String? actionError;
  final String? actionMessage;
  final bool isProcessing;

  SubscriptionsLoaded({
    required this.subscriptions,
    required this.creationOptions,
    this.trips = const [],
    this.rideUsage = const [],
    this.filters = const SubscriptionFilters(),
    this.activeTab = SubscriptionQueueTab.all,
    this.sortField = SubscriptionSortField.createdAt,
    this.sortAscending = false,
    this.selectedId,
    this.actionError,
    this.actionMessage,
    this.isProcessing = false,
  });

  UserSubscription? get selected {
    final id = selectedId;
    if (id == null) return null;
    for (final subscription in subscriptions) {
      if (subscription.id == id) return subscription;
    }
    return null;
  }

  SubscriptionTrip? get selectedTrip {
    if (!filters.hasTrip) return null;
    for (final trip in trips) {
      if (trip.id == filters.tripId) return trip;
    }
    return null;
  }

  /// The board for the trip in focus, or null when no trip is selected.
  /// Computed once per state instance: the screen reads it from the header,
  /// the KPI strip and the list.
  late final TripSubscriberBoard? tripBoard = _buildTripBoard();

  TripSubscriberBoard? _buildTripBoard() {
    final trip = selectedTrip;
    if (trip == null) return null;
    return TripSubscriberBoard.build(
      trip: trip,
      subscriptions: subscriptions,
      rideUsage: rideUsage,
    );
  }

  /// Subscriptions the trip filter admits. With no trip selected this is
  /// everything; with one, it is exactly the board's subscribers, in board
  /// order (work first).
  late final List<UserSubscription> _tripScoped = () {
    final board = tripBoard;
    if (board == null) return subscriptions;
    return board.subscribers
        .map((subscriber) => subscriber.subscription)
        .toList();
  }();

  late final List<UserSubscription> filteredSubscriptions = _filter();

  List<UserSubscription> _filter() {
    final search = filters.search.trim().toLowerCase();
    return _tripScoped.where((subscription) {
      if (!activeTab.matches(subscription)) return false;
      if (filters.routeId.isNotEmpty &&
          subscription.routeId != filters.routeId) {
        return false;
      }
      if (filters.packageName.isNotEmpty &&
          subscription.packageName != filters.packageName) {
        return false;
      }
      if (filters.unpaidOnly && !subscription.hasOutstandingBalance) {
        return false;
      }
      if (search.isEmpty) return true;
      return [
        subscription.userName,
        subscription.userPhone,
        subscription.packageName,
        subscription.routeLabel,
      ].join(' ').toLowerCase().contains(search);
    }).toList();
  }

  /// Sorted for display. A trip board is left in its own order — check-in
  /// state is a more useful sequence there than any column sort.
  late final List<UserSubscription> visibleSubscriptions = () {
    if (tripBoard != null) return filteredSubscriptions;
    final sorted = [...filteredSubscriptions]
      ..sort((a, b) {
        final result = sortField.compare(a, b);
        return sortAscending ? result : -result;
      });
    return sorted;
  }();

  /// The board rows still visible after tab/filter/search — so the trip view's
  /// cards keep their link chips and check-in actions.
  late final List<TripSubscriber> visibleTripSubscribers = () {
    final board = tripBoard;
    if (board == null) return const <TripSubscriber>[];
    final allowed = filteredSubscriptions.map((s) => s.id).toSet();
    return board.subscribers
        .where((subscriber) => allowed.contains(subscriber.subscription.id))
        .toList();
  }();

  int get resultCount => filteredSubscriptions.length;

  /// Tab counts are computed against the trip-scoped set, so selecting a trip
  /// re-counts the queues for that departure instead of the whole office.
  late final Map<SubscriptionQueueTab, int> _tabCounts = () {
    final counts = <SubscriptionQueueTab, int>{};
    for (final tab in SubscriptionQueueTab.values) {
      counts[tab] = _tripScoped.where(tab.matches).length;
    }
    return counts;
  }();

  int countForTab(SubscriptionQueueTab tab) => _tabCounts[tab] ?? 0;

  late final int activeCount = subscriptions
      .where((s) => s.status == SubscriptionStatus.active)
      .length;

  late final int pendingPaymentCount = subscriptions
      .where((s) => s.status == SubscriptionStatus.pendingPayment)
      .length;

  late final int expiringSoonCount = subscriptions
      .where((s) => s.isExpiringSoon)
      .length;

  /// Cash actually collected, not the value of everything sold.
  late final double collectedRevenue = subscriptions.fold<double>(
    0,
    (sum, s) => sum + s.paidAmount,
  );

  late final double outstandingRevenue = subscriptions.fold<double>(
    0,
    (sum, s) => sum + s.outstandingAmount,
  );

  /// Distinct package titles present, for the package filter. Picking from what
  /// exists beats typing a title that matches nothing.
  late final List<String> availablePackages =
      (subscriptions
          .map((s) => s.packageName.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList()
        ..sort());

  /// Routes that actually carry subscribers, so the route filter never offers a
  /// line with nothing behind it.
  late final Map<String, String> availableRoutes = () {
    final routes = <String, String>{};
    for (final subscription in subscriptions) {
      if (subscription.routeId.isEmpty) continue;
      routes[subscription.routeId] = subscription.routeLabel.isEmpty
          ? 'مسار'
          : subscription.routeLabel;
    }
    return routes;
  }();

  /// How many subscribers each trip would show, so the trip picker can carry a
  /// count and the operator can tell a busy departure from an empty one.
  int subscriberCountForTrip(SubscriptionTrip trip) {
    return TripSubscriberBoard.build(
      trip: trip,
      subscriptions: subscriptions,
      rideUsage: rideUsage,
    ).expectedCount;
  }

  SubscriptionsLoaded copyWith({
    List<UserSubscription>? subscriptions,
    List<SubscriptionTrip>? trips,
    List<SubscriptionRideUsage>? rideUsage,
    SubscriptionCreationOptions? creationOptions,
    SubscriptionFilters? filters,
    SubscriptionQueueTab? activeTab,
    SubscriptionSortField? sortField,
    bool? sortAscending,
    String? selectedId,
    bool clearSelection = false,
    String? actionError,
    bool clearActionError = false,
    String? actionMessage,
    bool clearActionMessage = false,
    bool? isProcessing,
  }) {
    return SubscriptionsLoaded(
      subscriptions: subscriptions ?? this.subscriptions,
      trips: trips ?? this.trips,
      rideUsage: rideUsage ?? this.rideUsage,
      creationOptions: creationOptions ?? this.creationOptions,
      filters: filters ?? this.filters,
      activeTab: activeTab ?? this.activeTab,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      selectedId: clearSelection ? null : selectedId ?? this.selectedId,
      actionError: clearActionError ? null : actionError ?? this.actionError,
      actionMessage: clearActionMessage
          ? null
          : actionMessage ?? this.actionMessage,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
