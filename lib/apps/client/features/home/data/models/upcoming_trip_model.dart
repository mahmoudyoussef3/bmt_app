import 'package:bmt_app/apps/client/core/utils/bookable_trip.dart';
import 'package:bmt_app/apps/client/core/utils/client_money.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';

/// Maps `public_trips` rows (joined to their route, office, seats and pricing)
/// into the departures feed.
abstract final class UpcomingTripMapper {
  /// [bookedStatus] and [bookedSeats] carry what the rider already holds on
  /// this departure, so the feed can mark it as booked while still offering it
  /// — riders book the same trip again for a friend.
  static UpcomingTripData fromRow(
    Map<String, dynamic> trip, {
    HomeBookingStatus? bookedStatus,
    int bookedSeats = 0,
  }) {
    final route = trip['route'] as Map<String, dynamic>? ?? const {};
    final startCity = route['start_city']?.toString() ?? '';
    final endCity = route['end_city']?.toString() ?? '';
    final routeName = route['name']?.toString().trim() ?? '';
    final office = trip['office'] as Map<String, dynamic>? ?? const {};

    return UpcomingTripData(
      tripId: trip['id']?.toString() ?? '',
      routeId: trip['route_id']?.toString() ?? route['id']?.toString() ?? '',
      routeName: routeName.isNotEmpty ? routeName : '$startCity → $endCity',
      pickup: startCity,
      destination: endCity,
      tripDate: trip['trip_date']?.toString() ?? '',
      departureTime: trip['departure_time']?.toString() ?? '',
      duration: route['duration']?.toString() ?? '',
      price: tripFareLabel(trip),
      seatsLeft: BookableTrip.seatsLeft(trip),
      isLive: trip['status'] == 'boarding' || trip['status'] == 'in_progress',
      officeId: office['id']?.toString() ?? '',
      officeName: office['name']?.toString() ?? '',
      bookedStatus: bookedStatus,
      bookedSeats: bookedSeats,
    );
  }
}
