import '../../domain/entities/my_subscription.dart';

/// Maps the `subscriptions` row the rider owns into [MySubscription].
abstract final class MySubscriptionMapper {
  /// `null` when the rider holds no active subscription.
  static MySubscription? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;
    return MySubscription(
      id: row['id']?.toString() ?? '',
      packageName: row['package_name']?.toString() ?? '',
      routeName: row['route_name']?.toString() ?? '',
      status: row['status']?.toString() ?? '',
      startDate: DateTime.tryParse(row['start_date']?.toString() ?? ''),
      endDate: DateTime.tryParse(row['end_date']?.toString() ?? ''),
      tripsTotal: int.tryParse(row['trips_count']?.toString() ?? '') ?? 0,
      tripsUsed: int.tryParse(row['trips_used']?.toString() ?? '') ?? 0,
    );
  }
}
