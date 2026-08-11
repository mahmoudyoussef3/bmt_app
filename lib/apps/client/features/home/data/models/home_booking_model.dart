import 'package:bmt_app/apps/client/core/utils/client_money.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';

/// Maps `operation_bookings` rows into the seats Home shows back to the rider.
abstract final class HomeBookingMapper {
  /// Returns `null` when the row is not a live commitment (draft, completed or
  /// cancelled), so Home only ever shows bookings the rider can still act on.
  static HomeBookingData? fromRow(Map<String, dynamic> row) {
    
    if (_tripEnded(row['operation_trips'])) return null;

    final status = HomeBookingStatus.fromRow(row['status']?.toString());
    if (status == null) return null;

    final pickup = row['pickup_point_name']?.toString().trim() ?? '';
    final dropoff = row['dropoff_point_name']?.toString().trim() ?? '';
    final endpoints = _routeEndpoints(row['route']?.toString() ?? '');

    return HomeBookingData(
      id: row['id']?.toString() ?? '',
      tripId: row['trip_id']?.toString() ?? '',
      bookingNumber: row['booking_number']?.toString() ?? '',
      status: status,
      pickup: pickup.isNotEmpty ? pickup : endpoints.$1,
      destination: dropoff.isNotEmpty ? dropoff : endpoints.$2,
      tripDate: row['trip_date']?.toString() ?? '',
      departureTime: row['trip_time']?.toString() ?? '',
      seatLabel: row['seat']?.toString().trim() ?? '',
      fare: moneyLabel(row['payment_amount'] as num?),
    );
  }

  /// Reads the embedded `operation_trips(status)`; `true` once the trip has
  /// `completed` or been `cancelled`. A missing embed (older query, RLS) reads
  /// as not-ended so a booking is never hidden on incomplete data.
  static bool _tripEnded(Object? trip) {
    final status = (trip is Map<String, dynamic> ? trip['status'] : null)
        ?.toString()
        .trim()
        .toLowerCase();
    return status == 'completed' || status == 'cancelled';
  }

  /// `route` is the free-text label a booking was created with, such as
  /// "Cairo → Alexandria". It is the fallback for rows where the point-name
  /// columns are empty; anything unparseable degrades to a blank destination
  /// rather than to a wrong city.
  static (String, String) _routeEndpoints(String route) {
    for (final separator in const [' → ', ' - ', ' to ']) {
      final parts = route.split(separator);
      if (parts.length == 2) return (parts.first.trim(), parts.last.trim());
    }
    return (route.trim(), '');
  }
}
