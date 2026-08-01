/// A trip the office runs, reduced to what the Subscriptions module needs to
/// filter by it and to label it in a picker.
///
/// Sourced from `operation_trips` joined to `operation_routes`; the module never
/// invents a trip, so an empty list means the office genuinely has none.
class SubscriptionTrip {
  final String id;
  final String code;
  final String routeId;
  final String routeName;
  final DateTime? date;
  final String departureTime;
  final String status;

  const SubscriptionTrip({
    required this.id,
    required this.code,
    required this.routeId,
    required this.routeName,
    required this.date,
    required this.departureTime,
    required this.status,
  });

  /// `TR-224156 · marg - new cairo · 2026/07/16 · 13:00` — everything an
  /// operator needs to recognise the departure they are working on.
  String get label {
    final parts = <String>[
      if (code.isNotEmpty) code,
      if (routeName.isNotEmpty) routeName,
      if (date != null) _formatDate(date!),
      if (departureTime.isNotEmpty) _formatTime(departureTime),
    ];
    return parts.isEmpty ? 'رحلة' : parts.join(' · ');
  }

  String get shortLabel {
    final parts = <String>[
      if (code.isNotEmpty) code,
      if (date != null) _formatDate(date!),
    ];
    return parts.isEmpty ? 'رحلة' : parts.join(' · ');
  }

  static String _formatDate(DateTime value) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${value.year}/${two(value.month)}/${two(value.day)}';
  }

  /// Postgres hands back `13:00:00`; the seconds are noise on a departure board.
  static String _formatTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;
    return '${parts[0]}:${parts[1]}';
  }
}

/// One ride burnt off a subscription, as recorded in `subscription_ride_usage`.
///
/// This is what makes "who already rode this trip on their subscription"
/// answerable — before the ledger existed, consuming a ride left no trace of
/// which departure it was spent on.
class SubscriptionRideUsage {
  final String id;
  final String subscriptionId;
  final String? tripId;
  final DateTime usedAt;

  const SubscriptionRideUsage({
    required this.id,
    required this.subscriptionId,
    required this.tripId,
    required this.usedAt,
  });
}
