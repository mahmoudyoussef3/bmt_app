/// The axes an operator narrows the subscriber list along.
///
/// Status is deliberately absent: it is the tab strip, not a filter, because
/// "which queue am I working" and "which slice of it" are different questions.
class SubscriptionFilters {
  final String search;

  /// A specific departure. When set, the list answers "who on this trip is on a
  /// subscription" rather than "who subscribes at all" — see
  /// `TripSubscriberLink` for how a subscription attaches to a trip.
  final String tripId;

  /// An `operation_routes` id. Broader than [tripId]: every subscriber on the
  /// line, across all its departures.
  final String routeId;

  /// Package title, matched exactly against what the subscription was sold as.
  final String packageName;

  /// Only subscribers who still owe money.
  final bool unpaidOnly;

  const SubscriptionFilters({
    this.search = '',
    this.tripId = '',
    this.routeId = '',
    this.packageName = '',
    this.unpaidOnly = false,
  });

  bool get hasTrip => tripId.isNotEmpty;

  bool get isActive =>
      search.trim().isNotEmpty ||
      tripId.isNotEmpty ||
      routeId.isNotEmpty ||
      packageName.isNotEmpty ||
      unpaidOnly;

  int get activeCount => [
    search.trim().isNotEmpty,
    tripId.isNotEmpty,
    routeId.isNotEmpty,
    packageName.isNotEmpty,
    unpaidOnly,
  ].where((active) => active).length;

  SubscriptionFilters copyWith({
    String? search,
    String? tripId,
    String? routeId,
    String? packageName,
    bool? unpaidOnly,
  }) {
    return SubscriptionFilters(
      search: search ?? this.search,
      tripId: tripId ?? this.tripId,
      routeId: routeId ?? this.routeId,
      packageName: packageName ?? this.packageName,
      unpaidOnly: unpaidOnly ?? this.unpaidOnly,
    );
  }
}
